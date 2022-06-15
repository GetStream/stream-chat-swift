//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// The type responsible for holding and refreshing the access token.
protocol TokenHandler: AnyObject {
    /// The currently used token.
    var currentToken: Token? { get }
    
    /// The user connection provider.
    var connectionProvider: UserConnectionProvider { get set }
    
    /// Assignes the given value to the `currentToken`, propagates it to the waiters, and cancels the ongoing refresh process.
    /// - Parameter token: The token to set.
    func set(token: Token, completion: ((Error?) -> Void)?)
    
    /// Triggers the token refresh process. When refresh process is completed, updates `currentToken` with the new value and completes token waiters.
    /// - Parameter completion: The completion that will be called when the token is fetched.
    func refreshToken(completion: @escaping TokenWaiter)
    
    /// Adds the new token waiter without initiating the token refresh process.
    /// - Parameter completion: The completion that will be called when token is fetched.
    @discardableResult
    func add(tokenWaiter: @escaping TokenWaiter) -> WaiterToken
    
    /// Removes the waiter with the given token from the list of waiters.
    /// - Parameter token: The waiter's token
    func removeTokenWaiter(_ token: WaiterToken)
    
    /// Cancels all token waiters with the given error and interrupts ongoing refresh process.
    /// - Parameter error: The error to cancel waiters with.
    func cancelRefreshFlow(with error: Error)
}

final class DefaultTokenHandler: TokenHandler {
    private let maximumTokenRefreshAttempts: Int
    private let retryTimeoutInterval: TimeInterval
    private let timerType: Timer.Type
    private var retryStrategy: RetryStrategy
    private var retryTimer: TimerControl?
    private var retryTimeoutTimer: TimerControl?

    @Atomic private var isRefreshingToken: Bool = false
    @Atomic private var tokenWaiters: [WaiterToken: TokenWaiter] = [:]
    
    private(set) var currentToken: Token?
    
    var connectionProvider: UserConnectionProvider {
        didSet {
            guard let oldUserId = oldValue.userId, connectionProvider.userId != oldUserId else { return }
            
            log.info("ℹ️ Token provider for another user is assigned.", subsystems: .tokenRefresh)
            
            let error = ClientError.UserDoesNotExist(userId: oldUserId)
            handleTokenResult(.failure(error))
        }
    }
    
    // MARK: - Init & Deinit
    
    init(
        connectionProvider: UserConnectionProvider,
        retryStrategy: RetryStrategy,
        retryTimeoutInterval: TimeInterval,
        maximumTokenRefreshAttempts: Int,
        timerType: Timer.Type
    ) {
        self.connectionProvider = connectionProvider
        self.retryStrategy = retryStrategy
        self.retryTimeoutInterval = retryTimeoutInterval
        self.maximumTokenRefreshAttempts = maximumTokenRefreshAttempts
        self.timerType = timerType
    }
    
    deinit {
        let error = ClientError.ClientHasBeenDeallocated()
        cancelRefreshFlow(with: error)
    }
    
    // MARK: - TokenHandler
    
    func set(token: Token, completion: ((Error?) -> Void)?) {
        if let userId = connectionProvider.userId, token.userId != userId {
            let message = "❌ Setting the token for another user is forbidden"
            log.error(message, subsystems: .tokenRefresh)
            completion?(ClientError.InvalidToken(message))
            return
        }
        
        handleTokenResult(.success(token))
        completion?(nil)
    }
    
    func cancelRefreshFlow(with error: Error) {
        log.info("ℹ️ Ongoing token refresh process is cancelled", subsystems: .tokenRefresh)
        
        handleTokenResult(.failure(error), updateToken: false)
    }
    
    func refreshToken(completion: @escaping TokenWaiter) {
        let shouldTriggerRefresh = initiateRefreshIfNotRunning()
        
        _ = add(tokenWaiter: completion)
        
        guard shouldTriggerRefresh else {
            let message = """
                ℹ️ Token refresh is initiated but it's already running.
                Only one refresh process can be active at a time.
                The caller will just wait for process to be completed
            """
            log.info(message, subsystems: .tokenRefresh)
            return
        }
        
        log.info("🚀 Token refresh process is started.", subsystems: .tokenRefresh)
        
        retryRefresh(of: currentToken, using: connectionProvider) { [weak self] in
            self?.handleTokenResult($0)
        }
    }
    
    @discardableResult
    func add(tokenWaiter: @escaping TokenWaiter) -> WaiterToken {
        let waiterToken: String = .newUniqueId
        
        if let token = currentToken, !isRefreshingToken {
            tokenWaiter(.success(token))
        } else {
            _tokenWaiters.mutate {
                $0[waiterToken] = tokenWaiter
            }
        }
        
        return waiterToken
    }
    
    func removeTokenWaiter(_ token: WaiterToken) {
        _tokenWaiters.mutate {
            $0[token] = nil
        }
    }
    
    // MARK: - Private
    
    private func retryRefresh(
        of token: Token?,
        using provider: UserConnectionProvider,
        completion: @escaping (Result<Token, Error>) -> Void
    ) {
        guard retryStrategy.consecutiveFailuresCount < maximumTokenRefreshAttempts else {
            let message = """
            ❌ Token refresh failed : all attempts are used \(retryStrategy.consecutiveFailuresCount)
            """
            log.error(message, subsystems: .tokenRefresh)
            completion(.failure(ClientError.TooManyTokenRefreshAttempts()))
            return
        }
        
        let delay = nextRetryDelay
        let attempt = retryStrategy.consecutiveFailuresCount + 1
        
        log.info("⏳ Will fetch token in \(delay) sec (\(attempt) attempt)", subsystems: .tokenRefresh)
        
        retryTimer = timerType.schedule(timeInterval: delay, queue: .main) { [weak self] in
            guard let self = self else { return }
            
            var attemptHasTimedOut = false
            
            self.retryTimeoutTimer = self.timerType.schedule(timeInterval: self.retryTimeoutInterval, queue: .main) {
                log.info("⏰ Timeout (\(attempt) attempt)", subsystems: .tokenRefresh)
                
                attemptHasTimedOut = true
                self.retryStrategy.incrementConsecutiveFailures()
                self.retryRefresh(of: token, using: provider, completion: completion)
            }
            
            log.info("🔥 Fetching token... (\(attempt) attempt)", subsystems: .tokenRefresh)
            
            provider.fetchToken { [weak self] in
                guard let self = self else {
                    return
                }
                
                guard !attemptHasTimedOut else {
                    log.info("ℹ️ The token is returned after the timeout", subsystems: .tokenRefresh)
                    return
                }
                
                self.retryTimeoutTimer?.cancel()
                self.retryTimeoutTimer = nil
                
                guard self.currentToken == token else {
                    let message = """
                        ℹ️ The `currentToken` was assinged while the refresh process.
                        The token returned by `tokenProvider` will be discarded.
                    """
                    log.info(message, subsystems: .tokenRefresh)
                    return
                }
                
                guard self.connectionProvider.userId == provider.userId else {
                    let message = """
                        ℹ️ The `tokenProvider` for the new user was assinged while the refresh process.
                        The token returned by `tokenProvider` will be discarded.
                    """
                    log.info(message, subsystems: .tokenRefresh)
                    return
                }
                
                switch $0 {
                case let .success(newToken):
                    log.info("📥 Token is fetched after \(attempt) attempt.", subsystems: .tokenRefresh)
                    
                    if newToken == token {
                        let message = "❌ Token refresh failed: the old token is returned"
                        completion(.failure(ClientError.InvalidToken(message)))
                    } else if newToken.userId != provider.userId {
                        let message = "❌ Token refresh failed: the token for another user is returned."
                        completion(.failure(ClientError.InvalidToken(message)))
                    } else if newToken.isExpired {
                        let message = "❌ Token refresh failed: an expired token is returned"
                        completion(.failure(ClientError.ExpiredToken(message)))
                    } else {
                        completion(.success(newToken))
                    }
                case let .failure(error):
                    log.info("❌ Token fetching has failed (\(attempt) attempt): \(error.localizedDescription)", subsystems: .tokenRefresh)
                    
                    self.retryStrategy.incrementConsecutiveFailures()
                    self.retryRefresh(of: token, using: provider, completion: completion)
                }
            }
        }
    }
    
    private var nextRetryDelay: TimeInterval {
        retryStrategy.consecutiveFailuresCount > 0
            ? retryStrategy.nextRetryDelay()
            : 0
    }
    
    private func handleTokenResult(_ result: Result<Token, Error>, updateToken: Bool = true) {
        if updateToken {
            switch result {
            case let .success(token):
                log.info("✅ Assigning the new token, unblocking pending API requests.", subsystems: .tokenRefresh)
                
                currentToken = token
            case let .failure(error):
                log.info("❌ Resetting the current token, cancelling pending API requests with error: \(error.localizedDescription).", subsystems: .tokenRefresh)
                
                currentToken = nil
            }
        }
        
        retryStrategy.resetConsecutiveFailures()
        retryTimeoutTimer?.cancel()
        retryTimeoutTimer = nil
        retryTimer?.cancel()
        retryTimer = nil
        
        isRefreshingToken = false
        
        completeTokenWaiters(with: result)
    }
    
    private func initiateRefreshIfNotRunning() -> Bool {
        var initiate = false
        
        _isRefreshingToken.mutate { isRefreshingToken in
            guard !isRefreshingToken else { return }
            
            isRefreshingToken = true
            initiate = true
        }
        
        return initiate
    }
    
    private func completeTokenWaiters(with result: Result<Token, Error>) {
        var waiters: [TokenWaiter] = []
        
        _tokenWaiters.mutate {
            waiters = Array($0.values)
            $0.removeAll()
        }
        
        waiters.forEach { $0(result) }
    }
}
