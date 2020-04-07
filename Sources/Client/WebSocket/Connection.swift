//
//  Connection.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 23/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A web socket connection state.
public enum ConnectionState: Equatable {
    
    /// The websocket is not connected.
    case notConnected
    /// The websocket was connected, waiting for a `connectionId` for requests.
    case connecting
    /// The websocket was connected.
    case connected(UserConnection)
    /// The websocket is disconnecting.
    case disconnecting
    /// The websocket was disconnected.
    case disconnected(Error?)
    
    /// Checks if the connection state is `.connected`.
    public var isConnected: Bool {
        if case .connected = self {
            return true
        }
        
        return false
    }
    
    public static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.notConnected, .notConnected),
             (.connecting, .connecting),
             (.connected, .connected),
             (.disconnecting, .disconnecting),
             (.disconnected, .disconnected):
            return true
        default:
            return false
        }
    }
}
