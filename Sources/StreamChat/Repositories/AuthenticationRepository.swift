//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias TokenProvider = (@escaping (Result<Token, Error>) -> Void) -> Void

enum EnvironmentState {
    case firstConnection
    case newToken
    case newUser
}

protocol AuthenticationRepositoryDelegate: AnyObject {
    func didFinishSettingUpAuthenticationEnvironment(for state: EnvironmentState)
    func clearCurrentUserData(completion: @escaping (Error?) -> Void)
}

class AuthenticationRepository {
    private enum Constants {
        /// Maximum amount of consecutive token refresh attempts before failing
        static let maximumTokenRefreshAttempts = 10
    }

    private let tokenQueue: DispatchQueue = DispatchQueue(label: "io.getstream.auth-repository", attributes: .concurrent)
    private var _isGettingToken: Bool = false {
        didSet {
            guard oldValue != _isGettingToken else { return }
            _isGettingToken ? apiClient.enterTokenFetchMode() : apiClient.exitTokenFetchMode()
        }
    }

    private var _consecutiveRefreshFailures: Int = 0
    private var _currentUserId: UserId?
    private var _currentToken: Token?
    private var _tokenProvider: TokenProvider?
    private var _tokenRequestCompletions: [(Error?) -> Void] = []
    private var _tokenWaiters: [String: (Token?) -> Void] = [:]

    private var isGettingToken: Bool {
        get { tokenQueue.sync { _isGettingToken } }
        set { tokenQueue.async(flags: .barrier) { self._isGettingToken = newValue }}
    }

    private var consecutiveRefreshFailures: Int {
        get { tokenQueue.sync { _consecutiveRefreshFailures } }
        set { tokenQueue.async(flags: .barrier) { self._consecutiveRefreshFailures = newValue }}
    }

    private(set) var currentUserId: UserId? {
        get { tokenQueue.sync { _currentUserId } }
        set { tokenQueue.async(flags: .barrier) { self._currentUserId = newValue }}
    }

    private(set) var currentToken: Token? {
        get { tokenQueue.sync { _currentToken } }
        set { tokenQueue.async(flags: .barrier) {
            self._currentToken = newValue
            self._currentUserId = newValue?.userId
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

    /// An array of requests waiting for the token
    private(set) var tokenWaiters: [String: (Token?) -> Void] {
        get { tokenQueue.sync { _tokenWaiters } }
        set { tokenQueue.async(flags: .barrier) { self._tokenWaiters = newValue }}
    }

    weak var delegate: AuthenticationRepositoryDelegate?

    private let apiClient: APIClient
    private let databaseContainer: DatabaseContainer
    private let connectionRepository: ConnectionRepository
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

        if let currentUserId = currentUserId {
            connectionRepository.updateWebSocketEndpoint(with: currentUserId)
        }
    }

    /// Fetches the user saved in the database, if exists
    func fetchCurrentUser() {
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
    /// - Parameters:
    ///   - token: The token for the new user
    ///   - completeTokenWaiters: A boolean indicating if the token should be passed to the requests that are awaiting
    func setToken(token: Token, completeTokenWaiters: Bool) {
        updateToken(token: token, notifyTokenWaiters: completeTokenWaiters)
    }

    /// Establishes a connection for a  user.
    /// - Parameters:
    ///   - userInfo:       The user information that will be created OR updated if it exists.
    ///   - tokenProvider:  The block to be used to get a token.
    func connectUser(userInfo: UserInfo?, tokenProvider: @escaping TokenProvider, completion: @escaping (Error?) -> Void) {
        self.tokenProvider = tokenProvider
        scheduleTokenFetch(isRetry: false, userInfo: userInfo, tokenProvider: tokenProvider, completion: completion)
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

        scheduleTokenFetch(isRetry: false, userInfo: nil, tokenProvider: tokenProvider, completion: completion)
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

        log.assert(delegate != nil, "Delegate should not be nil at this point")

        switch state {
        case .firstConnection, .newToken:
            connectionRepository.updateWebSocketEndpoint(with: newToken, userInfo: userInfo)
            setToken(token: newToken, completeTokenWaiters: true)
            delegate?.didFinishSettingUpAuthenticationEnvironment(for: state)
            completion(nil)

        case .newUser:
            completeTokenWaiters(token: nil)
            setToken(token: newToken, completeTokenWaiters: false)
            delegate?.didFinishSettingUpAuthenticationEnvironment(for: state)

            // Setting a new connection is not possible in connectionless mode.
            guard connectionRepository.isClientInActiveMode else {
                completion(ClientError.ClientIsNotInActiveMode())
                return
            }

            connectionRepository.disconnect(source: .userInitiated) { [weak delegate, weak connectionRepository] in
                connectionRepository?.updateWebSocketEndpoint(with: newToken, userInfo: userInfo)
                delegate?.clearCurrentUserData(completion: completion)
            }
        }
    }

    func provideToken(timeout: TimeInterval = 10, completion: @escaping (Result<Token, Error>) -> Void) {
        if let token = currentToken {
            completion(.success(token))
            return
        }

        let waiterToken = String.newUniqueId
        let completion = timerType.addTimeout(timeout, to: completion, noValueError: ClientError.MissingToken()) { [weak self] in
            self?.invalidateTokenWaiter(waiterToken)
        }

        tokenWaiters[waiterToken] = completion
    }

    func completeTokenWaiters(token: Token?) {
        updateToken(token: token, notifyTokenWaiters: true)
    }

    private func updateToken(token: Token?, notifyTokenWaiters: Bool) {
        let waiters: [String: (Token?) -> Void] = tokenQueue.sync {
            _currentToken = token
            _currentUserId = token?.userId
            guard notifyTokenWaiters else { return [:] }
            let waiters = _tokenWaiters
            _tokenWaiters = [:]
            return waiters
        }

        waiters.forEach { $0.value(token) }
    }

    private func scheduleTokenFetch(isRetry: Bool, userInfo: UserInfo?, tokenProvider: @escaping TokenProvider, completion: @escaping (Error?) -> Void) {
        guard !isGettingToken || isRetry else {
            tokenRequestCompletions.append(completion)
            return
        }

        timerType.schedule(
            timeInterval: tokenExpirationRetryStrategy.getDelayAfterTheFailure(),
            queue: .main
        ) { [weak self] in
            log.debug("Firing timer for a new token request", subsystems: .authentication)
            self?.getToken(isRetry: isRetry, userInfo: userInfo, tokenProvider: tokenProvider, completion: completion)
        }
    }

    private func getToken(isRetry: Bool, userInfo: UserInfo?, tokenProvider: @escaping TokenProvider, completion: @escaping (Error?) -> Void) {
        tokenRequestCompletions.append(completion)
        guard !isGettingToken || isRetry else {
            log.debug("Trying to get a token while already getting one", subsystems: .authentication)
            return
        }

        isGettingToken = true

        let onCompletion: (Error?) -> Void = { [weak self] error in
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
                self._consecutiveRefreshFailures = 0
                return completions
            }
            completionBlocks?.forEach { $0(error) }
        }

        guard consecutiveRefreshFailures < Constants.maximumTokenRefreshAttempts else {
            onCompletion(ClientError.TooManyFailedTokenRefreshAttempts())
            return
        }

        let onTokenReceived: (Token) -> Void = { [weak self, weak connectionRepository] token in
            self?.prepareEnvironment(userInfo: userInfo, newToken: token) { error in
                // Errors thrown during `prepareEnvironment` cannot be recovered
                if let error = error {
                    onCompletion(error)
                    return
                }

                // We manually change the `connectionStatus` for passive client
                // to `disconnected` when environment was prepared correctly
                // (e.g. current user session is successfully restored).
                connectionRepository?.forceConnectionStatusForInactiveModeIfNeeded()
                connectionRepository?.connect(userInfo: userInfo, completion: onCompletion)
            }
        }

        let retryFetchIfPossible: (Error?) -> Void = { [weak self] error in
            guard let self = self else { return }
            self.consecutiveRefreshFailures += 1
            guard self.consecutiveRefreshFailures < Constants.maximumTokenRefreshAttempts else {
                onCompletion(error ?? ClientError.TooManyFailedTokenRefreshAttempts())
                return
            }

            // We don't need to pass the completion again, as it is already present in `tokenRequestCompletions`
            self.scheduleTokenFetch(isRetry: true, userInfo: userInfo, tokenProvider: tokenProvider, completion: { _ in })
        }

        log.debug("Requesting a new token", subsystems: .authentication)
        tokenProvider { [weak self] result in
            switch result {
            case let .success(newToken) where !newToken.isExpired:
                onTokenReceived(newToken)
                self?.tokenExpirationRetryStrategy.resetConsecutiveFailures()
            case .success:
                retryFetchIfPossible(nil)
            case let .failure(error):
                log.info("Failed fetching token with error: \(error)")
                retryFetchIfPossible(error)
            }
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

    private func invalidateTokenWaiter(_ waiter: WaiterToken) {
        tokenWaiters[waiter] = nil
    }
}

extension ClientError {
    public class TooManyFailedTokenRefreshAttempts: ClientError {
        override public var localizedDescription: String {
            """
                Token fetch has failed more than 10 times.
                Please make sure that your `tokenProvider` is correctly functioning.
            """
        }
    }
}
