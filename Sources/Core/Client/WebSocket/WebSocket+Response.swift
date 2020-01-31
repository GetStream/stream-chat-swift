//
//  WebSocket+Response.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 23/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebSocket {
    /// A web socket connection state.
    public enum Connection: Equatable {
        case notConnected
        case connecting
        case connected(_ connectionId: String, User)
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
}

extension WebSocket {
    /// A web socket event response.
    public struct Response: Decodable {
        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case cid = "cid"
            case created = "created_at"
        }
        
        private static let channelInfoSeparator: Character = ":"
        
        /// A channel type and id.
        public let cid: ChannelId?
        /// An web socket event.
        public let event: Event
        /// A created date.
        public let created: Date
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            cid = try container.decodeIfPresent(ChannelId.self, forKey: .cid)
            event = try Event(from: decoder)
            created = try container.decode(Date.self, forKey: .created)
        }
    }
}
