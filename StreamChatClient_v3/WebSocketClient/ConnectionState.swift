//
// ConnectionState.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias ConnectionId = String

/// A web socket connection state.
public enum ConnectionState: Equatable {
    /// Provides additional information about the source of disconnecting.
    public enum DisconnectionSource: Equatable {
        /// A user initiated web socket disconnecting.
        case userInitiated
        
        /// A server initiated web socket disconnecting, an optional error object is provided.
        case serverInitiated(error: ClientError? = nil)
        
        /// The system initiated web socket disconnecting.
        case systemInitiated
    }
    
    /// The web socket is not connected. Optionally contains an error, if the connection was disconnected due to an error.
    case notConnected(error: ClientError? = nil)
    
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
    public var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
    
    /// Returns false if the connection state is in the `notConnected` state.
    public var isActive: Bool {
        if case .notConnected = self {
            return false
        }
        return true
    }
}
