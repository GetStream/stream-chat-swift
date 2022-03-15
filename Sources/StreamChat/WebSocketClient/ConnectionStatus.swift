//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

// `ConnectionStatus` is just a simplified and friendlier wrapper around `WebSocketConnectionState`.

/// Describes the possible states of the client connection to the servers.
public enum ConnectionStatus: Equatable {
    /// The client is initialized but not connected to the remote server yet.
    case initialized
    
    /// The client is disconnected. This is an initial state. Optionally contains an error, if the connection was disconnected
    /// due to an error.
    case disconnected(error: ClientError? = nil)
    
    /// The client is in the process of connecting to the remote servers.
    case connecting
    
    /// The client is connected to the remote server.
    case connected
    
    /// The web socket is disconnecting.
    case disconnecting
}

extension ConnectionStatus {
    // In internal initializer used for convering internal `WebSocketConnectionState` to `ChatClientConnectionStatus`.
    init(webSocketConnectionState: WebSocketConnectionState) {
        switch webSocketConnectionState {
        case .initialized:
            self = .initialized
            
        case .connecting, .waitingForConnectionId:
            self = .connecting
            
        case .connected:
            self = .connected
            
        case .disconnecting:
            self = .disconnecting
            
        case let .disconnected(source):
            let isWaitingForReconnect = webSocketConnectionState.isAutomaticReconnectionEnabled || source.serverError?
                .isInvalidTokenError == true
            
            self = isWaitingForReconnect ? .connecting : .disconnected(error: source.serverError)
        }
    }
}

typealias ConnectionId = String

/// A web socket connection state.
enum WebSocketConnectionState: Equatable {
    /// Provides additional information about the source of disconnecting.
    enum DisconnectionSource: Equatable {
        /// A user initiated web socket disconnecting.
        case userInitiated
        
        /// A server initiated web socket disconnecting, an optional error object is provided.
        case serverInitiated(error: ClientError? = nil)
        
        /// The system initiated web socket disconnecting.
        case systemInitiated
        
        /// `WebSocketPingController` didn't get a pong response.
        case noPongReceived
        
        /// Returns the underlaying error if connection cut was initiated by the server.
        var serverError: ClientError? {
            guard case let .serverInitiated(error) = self else { return nil }
            
            return error
        }
    }
    
    /// The initial state meaning that  there was no atempt to connect yet.
    case initialized
    
    /// The web socket is not connected. Contains the source/reason why the disconnection has happened.
    case disconnected(source: DisconnectionSource)
    
    /// The web socket is connecting
    case connecting
    
    /// The web socket is connected, waiting for the connection id
    case waitingForConnectionId
    
    /// The web socket was connected.
    case connected(connectionId: ConnectionId)
    
    /// The web socket is disconnecting. `source` contains more info about the source of the event.
    case disconnecting(source: DisconnectionSource)
    
    /// Checks if the connection state is connected.
    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
    
    /// Returns false if the connection state is in the `notConnected` state.
    var isActive: Bool {
        if case .disconnected = self {
            return false
        }
        return true
    }
    
    /// Returns `true` is the state requires and allows automatic reconnection.
    var isAutomaticReconnectionEnabled: Bool {
        guard case let .disconnected(source) = self else { return false }
        
        switch source {
        case let .serverInitiated(clientError):
            if let wsEngineError = clientError?.underlyingError as? WebSocketEngineError,
               wsEngineError.code == WebSocketEngineError.stopErrorCode {
                // Don't reconnect on `stop` errors
                return false
            }
            
            if let serverInitiatedError = clientError?.underlyingError as? ErrorPayload {
                if serverInitiatedError.isInvalidTokenError {
                    // Don't reconnect on invalid token errors
                    return false
                }
                
                if serverInitiatedError.isClientError {
                    // Don't reconnect on client side errors
                    return false
                }
            }
            
            return true
        case .systemInitiated:
            return true
        case .noPongReceived:
            return true
        case .userInitiated:
            return false
        }
    }
}
