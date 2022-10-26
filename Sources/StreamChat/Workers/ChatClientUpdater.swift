//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class ChatClientUpdater {
    unowned var client: ChatClient

    init(client: ChatClient) {
        self.client = client
    }

    private enum EnvironmentState {
        case firstConnection
        case newToken
        case newUser
    }

    func prepareEnvironment(
        userInfo: UserInfo?,
        newToken: Token,
        completion: @escaping (Error?) -> Void
    ) {
        let state: EnvironmentState
        if client.currentUserId == nil {
            state = .firstConnection
        } else if newToken.userId == client.currentUserId {
            state = .newToken
        } else {
            state = .newUser
        }

        switch state {
        case .firstConnection:
            client.updateWebSocketEndpoint(with: newToken, userInfo: userInfo)
            client.updateUser(with: newToken, completeTokenWaiters: true, isFirstConnection: true)
            completion(nil)

        case .newToken:
            client.updateWebSocketEndpoint(with: newToken, userInfo: userInfo)

            guard newToken != client.currentToken else {
                completion(nil)
                return
            }

            client.updateUser(with: newToken, completeTokenWaiters: true, isFirstConnection: false)
            completion(nil)

        case .newUser:
            client.switchToNewUser(with: newToken)

            // Setting a new connection is not possible in connectionless mode.
            guard client.config.isClientInActiveMode else {
                completion(ClientError.ClientIsNotInActiveMode())
                return
            }

            disconnect(source: .userInitiated) { [weak client] in
                guard let client = client else {
                    completion(ClientError.ClientHasBeenDeallocated())
                    return
                }

                client.clearCurrentUserData(completion: completion)
                client.updateWebSocketEndpoint(with: newToken, userInfo: userInfo)
            }
        }
    }

    func reloadUserIfNeeded(
        userInfo: UserInfo? = nil,
        tokenProvider: TokenProvider?,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard let tokenProvider = tokenProvider else {
            completion?(ClientError.ConnectionWasNotInitiated())
            return
        }
        
        tokenProvider {
            switch $0 {
            case let .success(newToken):
                self.prepareEnvironment(userInfo: userInfo, newToken: newToken) { [weak self] error in
                    // Errors thrown during `prepareEnvironment` cannot be recovered
                    if let error = error {
                        completion?(error)
                        return
                    }
                    
                    guard let self = self else {
                        completion?(nil)
                        return
                    }
                    
                    // We manually change the `connectionStatus` for passive client
                    // to `disconnected` when environment was prepared correctly
                    // (e.g. current user session is successfully restored).
                    if !self.client.config.isClientInActiveMode {
                        self.client.connectionStatus = .disconnected(error: nil)
                    }
                    
                    self.connect(userInfo: userInfo, completion: completion)
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
    func disconnect(
        source: WebSocketConnectionState.DisconnectionSource = .userInitiated,
        completion: @escaping () -> Void
    ) {
        client.apiClient.flushRequestsQueue()
        client.syncRepository.cancelRecoveryFlow()
        
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
            client?.completeConnectionIdWaiters(connectionId: nil)
            
            completion()
        }
    }
}
