//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

typealias ErrorCompletionHandler = (Error?) -> Void

class ChatClientUpdater {
    unowned var client: ChatClient

    init(client: ChatClient) {
        self.client = client
    }

    func prepareEnvironment(
        userInfo: UserInfo,
        newToken: Token,
        completion: @escaping (Error?) -> Void
    ) {
        guard let currentUserId = client.currentUserId else {
            // Set the current user id
            client.currentUserId = newToken.userId
            // Set the web-socket endpoint
            client.webSocketClient?.connectEndpoint = .webSocketConnect(userInfo: userInfo)
            // Create background workers
            client.createBackgroundWorkers()
            completion(nil)
            return
        }
        
        guard newToken.userId == currentUserId else {
            // Setting a new user is not possible in connectionless mode.
            guard client.config.isClientInActiveMode else {
                completion(ClientError.ClientIsNotInActiveMode())
                return
            }

            // Update the current user id to the new one.
            client.currentUserId = newToken.userId

            // Disconnect from web-socket.
            disconnect(source: .userInitiated) { [weak client] in
                guard let client = client else {
                    completion(ClientError.ClientHasBeenDeallocated())
                    return
                }
                
                // Update web-socket endpoint.
                client.webSocketClient?.connectEndpoint = .webSocketConnect(userInfo: userInfo)

                // Re-create backgroundWorker's since they are related to the previous user.
                client.createBackgroundWorkers()
                
                // Stop tracking active components
                client.activeChannelControllers.removeAllObjects()
                client.activeChannelListControllers.removeAllObjects()
                
                // Reset all existing local data.
                client.databaseContainer.removeAllData(force: true, completion: completion)
            }
            
            return
        }

        // Set the web-socket endpoint
        if client.webSocketClient?.connectEndpoint == nil {
            client.webSocketClient?.connectEndpoint = .webSocketConnect(userInfo: userInfo)
        }

        guard newToken != client.currentToken else {
            completion(nil)
            return
        }

        // It makes more sense to create background workers here
        // other than in `init` because workers without currently logged-in
        // user do nothing.
        if client.backgroundWorkers.isEmpty {
            client.createBackgroundWorkers()
        }
        
        completion(nil)
    }

    func reloadUserIfNeeded(
        userInfo: UserInfo,
        completion: ((Error?) -> Void)? = nil
    ) {
        client.tokenHandler.refreshToken { [weak self] in
            guard let self = self else {
                completion?(ClientError.ClientHasBeenDeallocated())
                return
            }
            
            switch $0 {
            case let .success(newToken):
                self.prepareEnvironment(
                    userInfo: userInfo,
                    newToken: newToken
                ) { [weak self] error in
                    guard let self = self else {
                        completion?(ClientError.ClientHasBeenDeallocated())
                        return
                    }
                    
                    // Errors thrown during `prepareEnvironment` cannot be recovered
                    if let error = error {
                        completion?(error)
                        return
                    }
                    
                    // We manually change the `connectionStatus` for passive client
                    // to `disconnected` when environment was prepared correctly
                    // (e.g. current user session is successfully restored).
                    if !self.client.config.isClientInActiveMode {
                        self.client.connectionStatus = .disconnected(error: nil)
                    }
                    
                    self.connect(completion: completion)
                }
            case let .failure(error):
                completion?(error)
            }
        }
    }

    /// Connects the chat client the controller represents to the chat servers.
    ///
    /// When the connection is established, `ChatClient` starts receiving chat updates, and `currentUser` variable is available.
    ///
    /// - Parameter completion: Called when the connection is established. If the connection fails, the completion is
    /// called with an error.
    ///
    func connect(completion: ((Error?) -> Void)? = nil) {
        // Connecting is not possible in connectionless mode (duh)
        guard client.config.isClientInActiveMode else {
            completion?(ClientError.ClientIsNotInActiveMode())
            return
        }

        guard client.connectionId == nil else {
            log.warning("The client is already connected. Skipping the `connect` call.")
            completion?(nil)
            return
        }

        // Set up a waiter for the new connection id to know when the connection process is finished
        client.provideConnectionId {
            completion?($0.error)
        }

        client.webSocketClient?.connect()
    }

    /// Disconnects the chat client the controller represents from the chat servers. No further updates from the servers
    /// are received.
    func disconnect(
        source: WebSocketConnectionState.DisconnectionSource = .userInitiated,
        completion: @escaping () -> Void
    ) {
        client.apiClient.flushRequestsQueue()
        client.syncRepository.cancelRecoveryFlow()
        client.tokenHandler.cancelRefreshFlow(with: ClientError.ClientHasBeenDisconnected())
        
        // Disconnecting is not possible in connectionless mode (duh)
        guard client.config.isClientInActiveMode else {
            log.error(ClientError.ClientIsNotInActiveMode().localizedDescription)
            completion()
            return
        }

        if client.connectionId == nil {
            if source == .userInitiated {
                log.warning("The client is already disconnected. Skipping the `disconnect` call.")
            }
            completion()
            return
        }

        // Disconnect the web socket
        client.webSocketClient?.disconnect(source: source) { [weak client] in
            // Reset `connectionId`. This would happen asynchronously by the callback from WebSocketClient anyway, but it's
            // safer to do it here synchronously to immediately stop all API calls.
            client?.connectionId = nil

            // Remove all waiters for connectionId
            let error = ClientError.ClientHasBeenDisconnected()
            client?.completeConnectionIdWaiters(result: .failure(error))
            
            completion()
        }
    }
    
    /// Disconnects the web-socket if needed, refreshes the token and reconnects the web-socket once the token is refreshed.
    /// - Parameters:
    ///   - serverError: The server that led to to the disconnection.
    ///   - completion: The completion that will be called when ws reconnects.
    func handleExpiredTokenError(_ serverError: ClientError, completion: ErrorCompletionHandler? = nil) {
        let disconnectionSource: WebSocketConnectionState.DisconnectionSource = .serverInitiated(error: serverError)
        
        let disconnectIfNeeded: (@escaping ErrorCompletionHandler) -> Void = { [weak self] completion in
            guard let ws = self?.client.webSocketClient, ws.connectionState.isConnected else {
                completion(nil)
                return
            }
            
            ws.disconnect(source: disconnectionSource) {
                completion(nil)
            }
        }
        
        let refreshToken: (@escaping ErrorCompletionHandler) -> Void = { [weak client] completion in
            guard let client = client else {
                completion(ClientError.ClientHasBeenDeallocated())
                return
            }
            
            client.tokenHandler.refreshToken {
                completion($0.error)
            }
        }
        
        let reconnectIfNeeded: (@escaping ErrorCompletionHandler) -> Void = { [weak client] completion in
            guard let client = client else {
                completion(ClientError.ClientHasBeenDeallocated())
                return
            }
            
            guard let ws = client.webSocketClient, ws.connectionState == .disconnected(source: disconnectionSource) else {
                completion(nil)
                return
            }
            
            client.provideConnectionId { completion($0.error) }
            
            ws.connect()
        }
        
        disconnectIfNeeded { disconnectError in
            guard disconnectError == nil else {
                completion?(disconnectError)
                return
            }
            
            refreshToken { refreshError in
                guard refreshError == nil else {
                    completion?(refreshError)
                    return
                }
                
                reconnectIfNeeded { reconnectError in
                    completion?(reconnectError)
                }
            }
        }
    }
}
