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
            completion?(ClientError.InvalidToken("The token is for another user"))
            return
        }
        
        handleTokenResult(.success(token))
        completion?(nil)
    }
    
    func cancelRefreshFlow(with error: Error) {
        handleTokenResult(.failure(error), updateToken: false)
    }
    
    func refreshToken(completion: @escaping TokenWaiter) {
        let shouldTriggerRefresh = initiateRefreshIfNotRunning()
        
        _ = add(tokenWaiter: completion)
        
        guard shouldTriggerRefresh else {
            return
        }
                
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
            completion(.failure(ClientError.TooManyTokenRefreshAttempts()))
            return
        }
        
        let delay = nextRetryDelay
        let attempt = retryStrategy.consecutiveFailuresCount + 1
                
        retryTimer = timerType.schedule(timeInterval: delay, queue: .main) { [weak self] in
            guard let self = self else { return }
            
            var attemptHasTimedOut = false
            
            self.retryTimeoutTimer = self.timerType.schedule(timeInterval: self.retryTimeoutInterval, queue: .main) {
                attemptHasTimedOut = true
                self.retryStrategy.incrementConsecutiveFailures()
                self.retryRefresh(of: token, using: provider, completion: completion)
            }
                        
            provider.fetchToken { [weak self] in
                guard let self = self else {
                    return
                }
                
                guard !attemptHasTimedOut else {
                    return
                }
                
                self.retryTimeoutTimer?.cancel()
                self.retryTimeoutTimer = nil
                
                guard self.currentToken == token else {
                    return
                }
                
                guard self.connectionProvider.userId == provider.userId else {
                    return
                }
                
                switch $0 {
                case let .success(newToken):
                    if newToken == token {
                        let sameTokenError = """
                            Token refresh failed ❌: the old token was returned during the refresh proccess.
                            When connecting with a static token, make sure it has no expiration date.
                            When connecting with a `tokenProvider`, make sure to fetch the new token from the backend.
                        """
                        completion(.failure(ClientError.InvalidToken(sameTokenError)))
                    } else if newToken.userId != provider.userId {
                        let invalidTokenError = """
                            Token refresh failed ❌: The token for different user is returned.
                            Check your token refreshing logic and ensure it returns valid tokens.
                        """
                        completion(.failure(ClientError.InvalidToken(invalidTokenError)))
                    } else if newToken.isExpired {
                        let expiredTokenError = """
                            Token refresh failed ❌: the token returned from token provider is expired.
                            Check your token refreshing logic and ensure it returns valid tokens.
                        """
                        completion(.failure(ClientError.ExpiredToken(expiredTokenError)))
                    } else {
                        completion(.success(newToken))
                    }
                case let .failure:
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
                currentToken = token
            case let .failure(error):
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
