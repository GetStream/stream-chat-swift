//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Read: Codable, Hashable {
    public var lastRead: Date
    public var unreadMessages: Int
    public var lastReadMessageId: String? = nil
    public var user: UserObject? = nil

    public init(lastRead: Date, unreadMessages: Int, lastReadMessageId: String? = nil, user: UserObject? = nil) {
        self.lastRead = lastRead
        self.unreadMessages = unreadMessages
        self.lastReadMessageId = lastReadMessageId
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case lastRead = "last_read"
        case unreadMessages = "unread_messages"
        case lastReadMessageId = "last_read_message_id"
        case user
    }
}