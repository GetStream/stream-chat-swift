//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias TokenProvider = (@escaping (Result<Token, Error>) -> Void) -> Void

class AuthenticationRepository {
    private let tokenQueue: DispatchQueue = DispatchQueue(label: "io.getstream.auth-repository", attributes: .concurrent)
    private var _isGettingToken: Bool = false
    private var _currentToken: Token?
    private var _tokenProvider: TokenProvider?
    private var _tokenRequestCompletions: [(Error?) -> Void] = []

    private(set) var isGettingToken: Bool {
        get { tokenQueue.sync { _isGettingToken } }
        set { tokenQueue.async(flags: .barrier) { self._isGettingToken = newValue }}
    }

    private(set) var currentToken: Token? {
        get { tokenQueue.sync { _currentToken } }
        set { tokenQueue.async(flags: .barrier) { self._currentToken = newValue }}
    }

    private(set) var tokenProvider: TokenProvider? {
        get { tokenQueue.sync { _tokenProvider } }
        set { tokenQueue.async(flags: .barrier) { self._tokenProvider = newValue }}
    }

    private(set) var tokenRequestCompletions: [(Error?) -> Void] {
        get { tokenQueue.sync { _tokenRequestCompletions } }
        set { tokenQueue.async(flags: .barrier) { self._tokenRequestCompletions = newValue }}
    }

    private let apiClient: APIClient
    private let clientUpdater: ChatClientUpdater
    /// A timer that runs token refreshing job
    private var tokenRetryTimer: TimerControl?
    /// Retry timing strategy for refreshing an expiried token
    private var tokenExpirationRetryStrategy: RetryStrategy
    private let timerType: Timer.Type

    init(apiClient: APIClient, clientUpdater: ChatClientUpdater, tokenExpirationRetryStrategy: RetryStrategy, timerType: Timer.Type) {
        self.apiClient = apiClient
        self.clientUpdater = clientUpdater
        self.tokenExpirationRetryStrategy = tokenExpirationRetryStrategy
        self.timerType = timerType
    }

    /// Establishes a connection for a  user.
    /// - Parameters:
    ///   - userInfo:       The user information that will be created OR updated if it exists.
    ///   - tokenProvider:  The block to be used to get a token.
    func connectUser(with userInfo: UserInfo?, tokenProvider: @escaping TokenProvider, completion: @escaping (Error?) -> Void) {
        connect(userInfo: userInfo, tokenProvider: tokenProvider, completion: completion)
    }

    /// Establishes a connection for a guest user.
    /// - Parameters:
    ///   - userInfo: The user information that will be created OR updated if it exists.
    func connectGuestUser(userInfo: UserInfo, completion: @escaping (Error?) -> Void) {
        connect(
            userInfo: userInfo,
            tokenProvider: { [weak self] completion in
                self?.fetchGuestToken(userInfo: userInfo, completion: completion)
            },
            completion: completion
        )
    }

    private func connect(userInfo: UserInfo?, tokenProvider: @escaping TokenProvider, completion: @escaping (Error?) -> Void) {
        self.tokenProvider = tokenProvider
        getToken(userInfo: userInfo, tokenProvider: tokenProvider, completion: completion)
    }

    func logOutUser() {
        log.debug("Logging out user", subsystems: .authentication)
        tokenProvider = nil
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

        tokenRetryTimer = timerType.schedule(
            timeInterval: tokenExpirationRetryStrategy.getDelayAfterTheFailure(),
            queue: .main
        ) { [weak self] in
            log.debug("Firing timer for a new token request", subsystems: .authentication)
            self?.getToken(userInfo: nil, tokenProvider: tokenProviderCheckingSuccess, completion: completion)
        }
    }

    private func getToken(userInfo: UserInfo?, tokenProvider: @escaping TokenProvider, completion: @escaping (Error?) -> Void) {
        tokenRequestCompletions.append(completion)
        guard isGettingToken else {
            log.debug("Trying to get a token while already getting one", subsystems: .authentication)
            return
        }

        isGettingToken = true

        log.debug("Requesting a new token", subsystems: .authentication)
        clientUpdater.reloadUserIfNeeded(userInfo: userInfo, tokenProvider: tokenProvider) { [weak self] error in
            if let error = error {
                log.error("Error when getting token: \(error)", subsystems: .authentication)
            } else {
                log.debug("Successfully retrieved token", subsystems: .authentication)
            }
            self?.tokenQueue.sync {
                self?._tokenRequestCompletions.forEach { $0(error) }
                self?._tokenRequestCompletions = []
                self?._isGettingToken = false
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
}
