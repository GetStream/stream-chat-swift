//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type responsible for token refresh process.
protocol TokenRefreshFlow: AnyObject {
    /// Starts the token refresh process using the given token provider.
    /// - Parameters:
    ///   - token: The expired token.
    ///   - completion: The completion to be called with the refresh result.
    func refresh(token: Token?, completion: @escaping TokenWaiter)
}

final class DefaultTokenRefreshFlow: TokenRefreshFlow {
    private let tokenProvider: UserConnectionProvider
    private let maximumTokenRefreshAttempts: Int
    private let attemptTimeout: TimeInterval
    private let timerType: Timer.Type
    private var retryStrategy: RetryStrategy
    private var retryTimer: TimerControl?
    private var retryTimeoutTimer: TimerControl?
    
    init(
        tokenProvider: UserConnectionProvider,
        maximumTokenRefreshAttempts: Int,
        attemptTimeout: TimeInterval,
        retryStrategy: RetryStrategy,
        timerType: Timer.Type
    ) {
        self.tokenProvider = tokenProvider
        self.maximumTokenRefreshAttempts = maximumTokenRefreshAttempts
        self.attemptTimeout = attemptTimeout
        self.retryStrategy = retryStrategy
        self.timerType = timerType
    }
    
    // MARK: - TokenRefreshFlow
    
    func refresh(token: Token?, completion: @escaping TokenWaiter) {
        guard retryStrategy.consecutiveFailuresCount < maximumTokenRefreshAttempts else {
            let message = """
            ❌ Token refresh failed : all attempts are used \(retryStrategy.consecutiveFailuresCount)
            """
            log.error(message, subsystems: .tokenRefresh)
            completion(.failure(ClientError.TooManyTokenRefreshAttempts()))
            return
        }
        
        let delay = retryStrategy.consecutiveFailuresCount > 0
            ? retryStrategy.nextRetryDelay()
            : 0
        
        let attempt = retryStrategy.consecutiveFailuresCount + 1
        
        log.info("⏳ Will fetch token in \(delay) sec (\(attempt) attempt)", subsystems: .tokenRefresh)
        
        retryTimer = timerType.schedule(timeInterval: delay, queue: .main) { [weak self] in
            guard let self = self else { return }
            
            var attemptHasTimedOut = false
            
            self.retryTimeoutTimer = self.timerType.schedule(timeInterval: self.attemptTimeout, queue: .main) {
                log.info("⏰ Timeout (\(attempt) attempt)", subsystems: .tokenRefresh)
                
                attemptHasTimedOut = true
                self.retryStrategy.incrementConsecutiveFailures()
                self.refresh(token: token, completion: completion)
            }
            
            log.info("🔥 Fetching token... (\(attempt) attempt)", subsystems: .tokenRefresh)
            
            self.tokenProvider.fetchToken { [weak self] in
                guard let self = self else {
                    return
                }
                
                guard !attemptHasTimedOut else {
                    log.info("ℹ️ The token is returned after the timeout", subsystems: .tokenRefresh)
                    return
                }
                
                self.retryTimeoutTimer?.cancel()
                self.retryTimeoutTimer = nil
                
                switch $0 {
                case let .success(newToken):
                    log.info("📥 Token is fetched after \(attempt) attempt.", subsystems: .tokenRefresh)
                    
                    if newToken == token {
                        let message = "❌ Token refresh failed: the old token is returned"
                        completion(.failure(ClientError.InvalidToken(message)))
                    } else if newToken.userId != self.tokenProvider.userId {
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
                    self.refresh(token: token, completion: completion)
                }
            }
        }
    }
}
