//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class ChatClientUpdater {
    unowned var client: ChatClient

    init(client: ChatClient) {
        self.client = client
    }

    func prepareEnvironment(
        userInfo: UserInfo?,
        newToken: Token,
        completion: @escaping (Error?) -> Void
    ) throws {
        guard let currentUserId = client.currentUserId else {
            // Set the current user id
            client.currentUserId = newToken.userId
            // Set the token
            client.currentToken = newToken
            // Set the web-socket endpoint
            client.webSocketClient?.connectEndpoint = .webSocketConnect(userInfo: userInfo ?? .init(id: newToken.userId))
            // Create background workers
            client.createBackgroundWorkers()
            // Provide the token to pending API requests
            client.completeTokenWaiters(token: newToken)
            completion(nil)
            return
        }
        
        guard newToken.userId == currentUserId else {
            // Cancel all API requests since they are related to the previous user.
            client.completeTokenWaiters(token: nil)

            // Setting a new user is not possible in connectionless mode.
            guard client.config.isClientInActiveMode else {
                throw ClientError.ClientIsNotInActiveMode()
            }

            // Update the current user id to the new one.
            client.currentUserId = newToken.userId

            // Update the current token with the new one.
            client.currentToken = newToken

            // Disconnect from web-socket.
            disconnect(source: .systemInitiated)
            
            // Update web-socket endpoint.
            client.webSocketClient?.connectEndpoint = .webSocketConnect(
                userInfo: userInfo ?? .init(id: newToken.userId)
            )

            // Re-create backgroundWorker's since they are related to the previous user.
            client.createBackgroundWorkers()

            // Reset all existing local data.
            return try client.databaseContainer.removeAllData(force: false, completion: completion)
        }

        // Set the web-socket endpoint
        if client.webSocketClient?.connectEndpoint == nil {
            client.webSocketClient?.connectEndpoint = .webSocketConnect(userInfo: userInfo ?? .init(id: newToken.userId))
        }

        guard newToken != client.currentToken else {
            completion(nil)
            return
        }

        client.currentToken = newToken

        // Forward the new token to waiting requests.
        client.completeTokenWaiters(token: newToken)

        // It makes more sense to create background workers here
        // other than in `init` because workers without currently logged-in
        // user do nothing.
        if client.backgroundWorkers.isEmpty {
            client.createBackgroundWorkers()
        }
        
        completion(nil)
    }

    func reloadUserIfNeeded(
        userInfo: UserInfo? = nil,
        userConnectionProvider: UserConnectionProvider?,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard let userConnectionProvider = userConnectionProvider else {
            completion?(ClientError.ConnectionWasNotInitiated())
            return
        }
        
        userConnectionProvider.getToken(client) {
            switch $0 {
            case let .success(newToken):
                do {
                    // We manually change the `connectionStatus` for passive client
                    // to `disconnected` when environment was prepared correctly
                    // (e.g. current user session is successfully restored).
                    if !self.client.config.isClientInActiveMode {
                        self.client.connectionStatus = .disconnected(error: nil)
                    }
                    
                    try self.prepareEnvironment(
                        userInfo: userInfo,
                        newToken: newToken
                    ) { error in
                        if let error = error {
                            fatalError("\(error)")
                        }
                        
                        self.connect(
                            userInfo: userInfo,
                            completion: completion
                        )
                    }
                } catch {
                    completion?(error)
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
    func connect(
        userInfo: UserInfo? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
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
        client.provideConnectionId { [weak client] connectionId in
            if connectionId != nil {
                completion?(nil)
            } else {
                // Try to get a concrete error
                if case let .disconnected(source) = client?.webSocketClient?.connectionState {
                    completion?(ClientError.ConnectionNotSuccessful(with: source.serverError))
                } else {
                    completion?(ClientError.ConnectionNotSuccessful())
                }
            }
        }

        client.webSocketClient?.connect()
    }

    /// Disconnects the chat client the controller represents from the chat servers. No further updates from the servers
    /// are received.
    func disconnect(source: WebSocketConnectionState.DisconnectionSource = .userInitiated) {
        // Disconnecting is not possible in connectionless mode (duh)
        guard client.config.isClientInActiveMode else {
            log.error(ClientError.ClientIsNotInActiveMode().localizedDescription)
            return
        }

        if client.connectionId == nil {
            if source == .userInitiated {
                log.warning("The client is already disconnected. Skipping the `disconnect` call.")
            }
            return
        }

        // Disconnect the web socket
        client.webSocketClient?.disconnect(source: source)

        // Reset `connectionId`. This would happen asynchronously by the callback from WebSocketClient anyway, but it's
        // safer to do it here synchronously to immediately stop all API calls.
        client.connectionId = nil

        // Remove all waiters for connectionId
        client.completeConnectionIdWaiters(connectionId: nil)
    }
}
