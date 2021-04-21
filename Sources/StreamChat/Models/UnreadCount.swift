//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A struct containing information about unread counts of channels and messages.
public struct UnreadCount: Decodable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case currentUserUnreadCount = "me"
        case userUnreadCount = "user"
        case channels = "unread_channels"
        case messages = "total_unread_count"
    }
    
    /// The default value representing no unread channels and messages.
    public static let noUnread = UnreadCount(channels: 0, messages: 0)
    
    /// The number of channels with unread messages.
    public let channels: Int
    
    /// The number of unread messages across all channels.
    public let messages: Int
    
    init(channels: Int, messages: Int) {
        self.channels = channels
        self.messages = messages
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let channels = try container.decodeIfPresent(Int.self, forKey: .channels),
           let messages = try container.decodeIfPresent(Int.self, forKey: .messages) {
            self.channels = channels
            self.messages = messages
        } else if let currentUserUnreadCount = try container.decodeIfPresent(UnreadCount.self, forKey: .currentUserUnreadCount) {
            channels = currentUserUnreadCount.channels
            messages = currentUserUnreadCount.messages
        } else if let userUnreadCount = try container.decodeIfPresent(UnreadCount.self, forKey: .userUnreadCount) {
            channels = userUnreadCount.channels
            messages = userUnreadCount.messages
        } else {
            throw ClientError.EventDecoding(missingValue: "unread_channels, total_unread_count", for: Self.self)
        }
    }
}
