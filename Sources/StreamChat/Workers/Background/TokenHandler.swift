//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

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
    typealias TokenRefreshFlowBuilder = (UserConnectionProvider) -> TokenRefreshFlow
    
    private(set) var currentToken: Token?
    private let refreshFlowBuilder: TokenRefreshFlowBuilder
    @Atomic private(set) var refreshFlow: TokenRefreshFlow?
    @Atomic private var tokenWaiters: [WaiterToken: TokenWaiter] = [:]
    var connectionProvider: UserConnectionProvider = .noCurrentUser {
        didSet {
            guard let oldUserId = oldValue.userId, connectionProvider.userId != oldUserId else { return }
            
            log.info("ℹ️ Token provider for another user is assigned.", subsystems: .tokenRefresh)
            
            let error = ClientError.UserDoesNotExist(userId: oldUserId)
            handleTokenRefreshResult(.failure(error))
        }
    }
    
    // MARK: - Init & Deinit
    
    init(refreshFlowBuilder: @escaping TokenRefreshFlowBuilder) {
        self.refreshFlowBuilder = refreshFlowBuilder
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
        
        handleTokenRefreshResult(.success(token))
        completion?(nil)
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
        
        refreshFlow?.refresh(token: currentToken) { [weak self] in
            self?.handleTokenRefreshResult($0)
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
    
    func cancelRefreshFlow(with error: Error) {
        if isRefreshingToken {
            log.info("ℹ️ Ongoing token refresh process is cancelled", subsystems: .tokenRefresh)
        }
        
        refreshFlow = nil
        
        completeTokenWaiters(with: .failure(error))
    }
}

// MARK: - Private

private extension DefaultTokenHandler {
    var isRefreshingToken: Bool {
        refreshFlow != nil
    }

    func initiateRefreshIfNotRunning() -> Bool {
        var initiate = false
        
        _refreshFlow.mutate { flow in
            guard flow == nil else { return }
            
            flow = self.refreshFlowBuilder(self.connectionProvider)
            initiate = true
        }
        
        return initiate
    }
    
    func handleTokenRefreshResult(_ result: Result<Token, Error>) {
        switch result {
        case let .success(token):
            log.info("✅ Assigning the new token, unblocking pending API requests.", subsystems: .tokenRefresh)
            
            currentToken = token
        case let .failure(error):
            log.info("❌ Resetting the current token, cancelling pending API requests with error: \(error.localizedDescription).", subsystems: .tokenRefresh)
            
            currentToken = nil
        }
        
        refreshFlow = nil
        
        completeTokenWaiters(with: result)
    }
    
    func completeTokenWaiters(with result: Result<Token, Error>) {
        var waiters: [TokenWaiter] = []
        
        _tokenWaiters.mutate {
            waiters = Array($0.values)
            $0.removeAll()
        }
        
        waiters.forEach { $0(result) }
    }
}
