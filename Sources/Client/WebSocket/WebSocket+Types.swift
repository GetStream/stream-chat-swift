//
//  WebSocket+Types.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 23/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A typealias for thew Client `Event`.
public typealias ClientEvent = Event

public extension WebSocket {
    
    /// WebSocket Error
    struct ErrorContainer: Decodable {
        /// A server error was recieved.
        public let error: ClientErrorResponse
    }
    
    /// A websocket event.
    enum Event {
        /// The websocket was connected. The `connectiondId` recieved.
        case connected
        /// The websocket was disconnected with an error or it wasn't connected.
        case disconnected(Error?)
        /// A `Response` was recieved.
        case message(Response)
        /// A  pong event.
        case pong
    }
    
    /// A web socket connection state.
    enum Connection: Equatable {
        /// The websocket is not connected.
        case notConnected
        /// The websocket was connected, waiting for a `connectionId` for requests.
        case connecting
        /// The websocket was connected. The `connectiondId` and `User` was recieved.
        case connected(_ connectionId: String, User)
        /// The websocket was disconnected with an error.
        case disconnected(Swift.Error)
        
        /// Check if the web socket is connected.
        public var isConnected: Bool {
            if case .connected(let connectionId, _) = self {
                return !connectionId.isEmpty
            }
            
            return false
        }
        
        public static func == (lhs: Connection, rhs: Connection) -> Bool {
            switch (lhs, rhs) {
            case (.notConnected, .notConnected),
                 (.connecting, .connecting),
                 (.disconnected, .disconnected):
                return true
            case let (.connected(connectionId1, user1), .connected(connectionId2, user2)):
                return connectionId1 == connectionId2 && user1 == user2
            default:
                return false
            }
        }
    }
    
    /// A web socket event response.
    struct Response: Decodable {
        private enum CodingKeys: String, CodingKey {
            case cid = "cid"
            case created = "created_at"
        }
        
        private static let channelInfoSeparator: Character = ":"
        
        /// A channel type and id.
        public let cid: ChannelId?
        /// An web socket event.
        public let event: ClientEvent
        /// A created date.
        public let created: Date
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            cid = try container.decodeIfPresent(ChannelId.self, forKey: .cid)
            event = try ClientEvent(from: decoder)
            created = try container.decode(Date.self, forKey: .created)
        }
    }
}
