//
//  Connection.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 23/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A web socket connection state.
public enum Connection: Equatable {
    
    /// The websocket is not connected.
    case notConnected
    /// The websocket was connected, waiting for a `connectionId` for requests.
    case connecting
    /// The websocket was connected.
    case connected
    /// The websocket was disconnected with an error.
    case disconnected(Swift.Error?)
    
    public static func == (lhs: Connection, rhs: Connection) -> Bool {
        switch (lhs, rhs) {
        case (.notConnected, .notConnected),
             (.connecting, .connecting),
             (.connected, .connected):
            return true
        case (.disconnected(let error1), .disconnected(let error2)):
            return error1?.localizedDescription == error2?.localizedDescription
        default:
            return false
        }
    }
}
