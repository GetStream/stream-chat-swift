//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class TokenRefresher {
    /// Shows whether the token is being refreshed at the moment
    var isRefreshingToken: Bool {
        get {
            var value: Bool!
            queue.sync {
                value = _isRefreshingToken
            }
            return value
        }
        set {
            queue.async(flags: .barrier) {
                self._isRefreshingToken = newValue
            }
        }
    }

    private var _isRefreshingToken: Bool = false
    private var listeners: [(Result<Void, Error>) -> Void] = []
    private let queue = DispatchQueue(label: "io.stream.com.refresh-token")

    /// Used for reobtaining tokens when they expire and API client receives token expiration error
    var tokenRefreshBlock: TokenProvider?
    /// A timer that runs token refreshing job
    private var tokenRetryTimer: TimerControl?
    /// Retry timing strategy for refreshing an expiried token
    private var retryStrategy: RetryStrategy
    private let timerType: Timer.Type
    private let clientUpdater: ChatClientUpdater

    init(
        clientUpdater: ChatClientUpdater,
        timerType: Timer.Type,
        tokenExpirationRetryStrategy: RetryStrategy,
        tokenRefreshBlock: TokenProvider?
    ) {
        self.clientUpdater = clientUpdater
        self.timerType = timerType
        retryStrategy = tokenExpirationRetryStrategy
        self.tokenRefreshBlock = tokenRefreshBlock
    }

    func refreshToken(completion: ((Result<Void, Error>) -> Void)?) {
//        guard let tokenRefreshBlock = tokenRefreshBlock else {
//            return log.assertionFailure(
//                "In case if token expiration is enabled on backend you need to provide a way to reobtain it via `tokenProvider` on ChatClient"
//            )
//        }

        let tokenRefreshBlock: TokenProvider = { completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                completion(
                    .success(
                        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIiLCJleHAiOjE2NTM1NTczNjZ9.op7Ufec6Ijgz5ElpF1D-CKVz3bbAWG7Iq2SqZku8lis"
                    )
                )
            }
        }

        print("⚠️💥. TokenRefresher refreshToken call")

        var shouldKickRefresh: Bool = false
        queue.sync {
            shouldKickRefresh = !_isRefreshingToken
            if let completion = completion {
                listeners.append(completion)
            }
            _isRefreshingToken = true
        }

        guard shouldKickRefresh else {
            print("⚠️❌. Not kicking refresh. \(listeners.count) listeners")
            return
        }

        print("⚠️✅. TokenRefresher starting token refresh. \(listeners.count) listeners")
        executeRefresh(tokenProvider: tokenRefreshBlock) { [weak self] result in
            self?.queue.sync {
                print("⚠️. TokenRefresher completed token refresh. \(self?.listeners.count ?? 0) listeners")
                self?._isRefreshingToken = false
                self?.listeners.forEach {
                    $0(result)
                }
                self?.listeners = []
            }
        }
    }

    private func executeRefresh(tokenProvider: @escaping TokenProvider, completion: @escaping (Result<Void, Error>) -> Void) {
        let reconnectionDelay = retryStrategy.getDelayAfterTheFailure()
        tokenRetryTimer = timerType.schedule(timeInterval: reconnectionDelay, queue: .main) { [weak self, clientUpdater] in
            print("⚠️. TokenRefresher - timer triggered. \(self?.listeners.count ?? 0) listeners")
            clientUpdater.reloadUserIfNeeded(
                userConnectionProvider: .closure { _, completion in
                    tokenProvider { result in
                        print(
                            "⚠️🚀. TokenRefresher - reloadUserIfNeeded-tokenProvider completed. \(result) \(self?.listeners.count ?? 0) listeners"
                        )
                        if case .success = result {
                            self?.retryStrategy.resetConsecutiveFailures()
                        }
                        completion(result)
                    }
                },
                completion: { error in
                    print("⚠️📵. TokenRefresher - reloadUserIfNeeded completed. \(self?.listeners.count ?? 0) listeners")
                    completion(error.map { .failure($0) } ?? .success(()))
                }
            )
        }
    }
}
