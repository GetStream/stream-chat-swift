//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias TokenProvider = (@escaping (Result<Token, Error>) -> Void) -> Void

class AuthenticationRepository {
    private let tokenQueue = DispatchQueue(label: "io.getstream.auth-repository", attributes: .concurrent)

    private var _currentToken: Token?
    private(set) var currentToken: Token? {
        get { tokenQueue.sync { _currentToken } }
        set {
            tokenQueue.async(flags: .barrier) {
                self._currentToken = newValue
            }
        }
    }

    private var _tokenProvider: TokenProvider?
    private(set) var tokenProvider: TokenProvider? {
        get { tokenQueue.sync { _tokenProvider } }
        set {
            tokenQueue.async(flags: .barrier) {
                self._tokenProvider = newValue
            }
        }
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

    func connectUser(with userInfo: UserInfo?, tokenProvider: @escaping TokenProvider, completion: @escaping (Error?) -> Void) {
        connect(userInfo: userInfo, tokenProvider: tokenProvider, completion: completion)
    }

    /// Establishes a connection for a guest user.
    /// - Parameters:
    ///   - userId: The identifier a guest user will be created OR updated with if it exists.
    ///   - name: The name a guest user will be created OR updated with if it exists.
    ///   - imageURL: The avatar URL a guest user will be created OR updated with if it exists.
    ///   - extraData: The extra data a guest user will be created OR updated with if it exists.
    func connectGuestUser(userInfo: UserInfo, completion: @escaping (Error?) -> Void) {
        connect(
            userInfo: userInfo,
            tokenProvider: { [weak self] completion in
                self?.getGuestToken(userInfo: userInfo, completion: completion)
            },
            completion: completion
        )
    }

    private func connect(userInfo: UserInfo?, tokenProvider: @escaping TokenProvider, completion: @escaping (Error?) -> Void) {
        #warning("do not trigger this twice")
        self.tokenProvider = tokenProvider
        clientUpdater.reloadUserIfNeeded(userInfo: userInfo, tokenProvider: tokenProvider, completion: completion)
    }

    func logOutUser() {
        #warning("Handle removal of token and stuff here?")
        tokenProvider = nil
    }

    func refreshToken(completion: @escaping (Error?) -> Void) {
        #warning("do not trigger this twice")

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
        ) { [clientUpdater] in
            clientUpdater.reloadUserIfNeeded(tokenProvider: tokenProviderCheckingSuccess, completion: completion)
        }
    }

    private func getGuestToken(
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
