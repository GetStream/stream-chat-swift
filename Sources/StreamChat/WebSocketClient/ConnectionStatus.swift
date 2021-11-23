//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
            
        case let .disconnected(error: error):
            self = .disconnected(error: error)
            
        case .connecting, .waitingForConnectionId, .waitingForReconnect:
            self = .connecting
            
        case .connected:
            self = .connected
            
        case .disconnecting:
            self = .disconnecting
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
    }
    
    /// The initial state, there was no attempt to connect yet.
    case initialized
    
    /// The web socket is not connected. Optionally contains an error, if the connection was disconnected due to an error.
    case disconnected(error: ClientError? = nil)
    
    /// The web socket is connecting
    case connecting
    
    /// The web socket is connected, waiting for the connection id
    case waitingForConnectionId
    
    /// The web socket was connected.
    case connected(connectionId: ConnectionId)
    
    /// The web socket is disconnecting. `source` contains more info about the source of the event.
    case disconnecting(source: DisconnectionSource)
    
    /// The web socket is waiting for reconnecting. Optinally, an error is provided with the reason why it was disconnected.
    case waitingForReconnect(error: ClientError? = nil)
    
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
}
