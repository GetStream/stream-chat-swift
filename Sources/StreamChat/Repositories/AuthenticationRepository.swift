//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias TokenProvider = (@escaping (Result<Token, Error>) -> Void) -> Void

class AuthenticationRepository {
    private let tokenQueue: DispatchQueue = DispatchQueue(label: "io.getstream.auth-repository", attributes: .concurrent)
    private var _isGettingToken: Bool = false
    private var _currentUserId: UserId?
    private var _currentToken: Token?
    private var _tokenProvider: TokenProvider?
    private var _tokenRequestCompletions: [(Error?) -> Void] = []

    private var isGettingToken: Bool {
        get { tokenQueue.sync { _isGettingToken } }
        set { tokenQueue.async(flags: .barrier) { self._isGettingToken = newValue }}
    }

    private(set) var currentUserId: UserId? {
        get { tokenQueue.sync { _currentUserId } }
        set { tokenQueue.async(flags: .barrier) { self._currentUserId = newValue }}
    }

    private(set) var currentToken: Token? {
        get { tokenQueue.sync { _currentToken } }
        set { tokenQueue.async(flags: .barrier) {
            self._currentToken = newValue
            newValue.map { self._currentUserId = $0.userId }
        }}
    }

    private(set) var tokenProvider: TokenProvider? {
        get { tokenQueue.sync { _tokenProvider } }
        set { tokenQueue.async(flags: .barrier) { self._tokenProvider = newValue }}
    }

    private var tokenRequestCompletions: [(Error?) -> Void] {
        get { tokenQueue.sync { _tokenRequestCompletions } }
        set { tokenQueue.async(flags: .barrier) { self._tokenRequestCompletions = newValue }}
    }

    private let apiClient: APIClient
    private let databaseContainer: DatabaseContainer
    private let connectionRepository: ConnectionRepository
    /// A timer that runs token refreshing job
    private var tokenRetryTimer: TimerControl?
    /// Retry timing strategy for refreshing an expired token
    private var tokenExpirationRetryStrategy: RetryStrategy
    private let timerType: Timer.Type

    init(
        apiClient: APIClient,
        databaseContainer: DatabaseContainer,
        connectionRepository: ConnectionRepository,
        tokenExpirationRetryStrategy: RetryStrategy,
        timerType: Timer.Type
    ) {
        self.apiClient = apiClient
        self.databaseContainer = databaseContainer
        self.connectionRepository = connectionRepository
        self.tokenExpirationRetryStrategy = tokenExpirationRetryStrategy
        self.timerType = timerType

        fetchCurrentUser()
    }

    private func fetchCurrentUser() {
        var currentUserId: UserId?

        let context = databaseContainer.viewContext
        if Thread.isMainThread {
            currentUserId = context.currentUser?.user.id
        } else {
            context.performAndWait {
                currentUserId = context.currentUser?.user.id
            }
        }
        self.currentUserId = currentUserId
    }

    /// Sets the user token. This method is only needed to perform API calls without connecting as a user.
    /// You should only use this in special cases like a notification service or other background process
    func setToken(token: Token) {
        currentToken = token
    }

    /// Establishes a connection for a  user.
    /// - Parameters:
    ///   - userInfo:       The user information that will be created OR updated if it exists.
    ///   - tokenProvider:  The block to be used to get a token.
    func connectUser(userInfo: UserInfo?, tokenProvider: @escaping TokenProvider, completion: @escaping (Error?) -> Void) {
        self.tokenProvider = tokenProvider
        getToken(userInfo: userInfo, tokenProvider: tokenProvider, completion: completion)
    }

    /// Establishes a connection for a guest user.
    /// - Parameters:
    ///   - userInfo: The user information that will be created OR updated if it exists.
    func connectGuestUser(userInfo: UserInfo, completion: @escaping (Error?) -> Void) {
        connectUser(
            userInfo: userInfo,
            tokenProvider: { [weak self] completion in
                self?.fetchGuestToken(userInfo: userInfo, completion: completion)
            },
            completion: completion
        )
    }

    func clearTokenProvider() {
        tokenProvider = nil
    }

    func logOutUser() {
        log.debug("Logging out user", subsystems: .authentication)
        clearTokenProvider()
        currentToken = nil
        currentUserId = nil
    }

    func refreshToken(completion: @escaping (Error?) -> Void) {
        guard let tokenProvider = tokenProvider else {
            let error = ClientError.MissingTokenProvider()
            log.assertionFailure(error.localizedDescription)
            completion(error)
            return
        }

        let tokenProviderCheckingSuccess: TokenProvider = { [weak self] completion in
            tokenProvider { result in
                if case .success = result {
                    self?.tokenExpirationRetryStrategy.resetConsecutiveFailures()
                }
                completion(result)
            }
        }

        scheduleTokenFetch(userInfo: nil, tokenProvider: tokenProviderCheckingSuccess, completion: completion)
    }

    private enum EnvironmentState {
        case firstConnection
        case newToken
        case newUser
    }

    func prepareEnvironment(
        userInfo: UserInfo?,
        newToken: Token,
        completion: @escaping (Error?) -> Void
    ) {
        let state: EnvironmentState
        if currentUserId == nil {
            state = .firstConnection
        } else if newToken.userId == currentUserId {
            state = .newToken
        } else {
            state = .newUser
        }

        switch state {
        case .firstConnection:
            client.updateWebSocketEndpoint(with: newToken, userInfo: userInfo)
            client.updateUser(with: newToken, completeTokenWaiters: true, isFirstConnection: true)
            completion(nil)

        case .newToken:
            client.updateWebSocketEndpoint(with: newToken, userInfo: userInfo)
            client.updateUser(with: newToken, completeTokenWaiters: true, isFirstConnection: false)
            completion(nil)

        case .newUser:
            client.switchToNewUser(with: newToken)

            // Setting a new connection is not possible in connectionless mode.
            guard client.config.isClientInActiveMode else {
                completion(ClientError.ClientIsNotInActiveMode())
                return
            }

            connectionRepository.disconnect(source: .userInitiated) { [weak client] in
                guard let client = client else {
                    completion(ClientError.ClientHasBeenDeallocated())
                    return
                }

                client.clearCurrentUserData(completion: completion)
                client.updateWebSocketEndpoint(with: newToken, userInfo: userInfo)
            }
        }
    }

    #warning("Rename???")
    func reloadUserIfNeeded(
        userInfo: UserInfo? = nil,
        tokenProvider: TokenProvider?,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard let tokenProvider = tokenProvider else {
            completion?(ClientError.ConnectionWasNotInitiated())
            return
        }

        // Check if userIds match, and if token is expired. If userIds are the same, and token is not expired, don't perform this whole dance.
        // BUTTTTTT we might need to call connect()

        tokenProvider { [weak self, weak connectionRepository] in
            switch $0 {
            case let .success(newToken):
                self?.prepareEnvironment(userInfo: userInfo, newToken: newToken) { error in
                    // Errors thrown during `prepareEnvironment` cannot be recovered
                    if let error = error {
                        completion?(error)
                        return
                    }

                    guard let self = self else {
                        completion?(nil)
                        return
                    }

                    // We manually change the `connectionStatus` for passive client
                    // to `disconnected` when environment was prepared correctly
                    // (e.g. current user session is successfully restored).
                    if !self.client.config.isClientInActiveMode {
                        self.client.connectionStatus = .disconnected(error: nil)
                    }

                    connectionRepository?.connect(userInfo: userInfo, completion: completion)
                }
            case let .failure(error):
                completion?(error)
            }
        }
    }

    private func scheduleTokenFetch(userInfo: UserInfo?, tokenProvider: @escaping TokenProvider, completion: @escaping (Error?) -> Void) {
        guard !isGettingToken else {
            tokenRequestCompletions.append(completion)
            return
        }

        tokenRetryTimer = timerType.schedule(
            timeInterval: tokenExpirationRetryStrategy.getDelayAfterTheFailure(),
            queue: .main
        ) { [weak self] in
            log.debug("Firing timer for a new token request", subsystems: .authentication)
            self?.getToken(userInfo: nil, tokenProvider: tokenProvider, completion: completion)
        }
    }

    private func getToken(userInfo: UserInfo?, tokenProvider: @escaping TokenProvider, completion: @escaping (Error?) -> Void) {
        tokenRequestCompletions.append(completion)
        guard !isGettingToken else {
            log.debug("Trying to get a token while already getting one", subsystems: .authentication)
            return
        }

        isGettingToken = true
        log.debug("Requesting a new token", subsystems: .authentication)
        reloadUserIfNeeded(userInfo: userInfo, tokenProvider: tokenProvider) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                log.error("Error when getting token: \(error)", subsystems: .authentication)
            } else {
                log.debug("Successfully retrieved token", subsystems: .authentication)
            }

            let completionBlocks: [(Error?) -> Void]? = self.tokenQueue.sync {
                self._isGettingToken = false
                let completions = self._tokenRequestCompletions
                self._tokenRequestCompletions = []
                return completions
            }
            completionBlocks?.forEach { $0(error) }
        }
    }

    private func fetchGuestToken(
        userInfo: UserInfo,
        completion: @escaping (Result<Token, Error>) -> Void
    ) {
        let endpoint: Endpoint<GuestUserTokenPayload> = .guestUserToken(
            userId: userInfo.id,
            name: userInfo.name,
            imageURL: userInfo.imageURL,
            extraData: userInfo.extraData
        )
        apiClient.request(endpoint: endpoint) {
            switch $0 {
            case let .success(payload):
                let token = payload.token
                completion(.success(token))
            case let .failure(error):
                log.error(error)
                completion(.failure(error))
            }
        }
    }
}
