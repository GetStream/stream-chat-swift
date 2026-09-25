//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NotificationMarkReadEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    /// The CID of the channel which was marked as read
    let cid: ChannelId?
    /// Date/time of creation
    let createdAt: Date
    let groupedUnreadChannels: [String: Int]?
    /// The ID of the last read message
    let lastReadMessageId: String?
    let thread: ThreadResponse?
    /// The total number of unread messages
    let totalUnreadCount: Int
    /// The type of event: "notification.mark_read" in this case
    let type: String
    /// The number of channels with unread messages
    let unreadChannels: Int
    /// The number of unread threads
    let unreadThreads: Int?
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload? = nil,
        cid: ChannelId? = nil,
        createdAt: Date,
        groupedUnreadChannels: [String: Int]? = nil,
        lastReadMessageId: String? = nil,
        thread: ThreadResponse? = nil,
        totalUnreadCount: Int,
        type: String = "notification.mark_read",
        unreadChannels: Int,
        unreadThreads: Int? = nil,
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.cid = cid
        self.createdAt = createdAt
        self.groupedUnreadChannels = groupedUnreadChannels
        self.lastReadMessageId = lastReadMessageId
        self.thread = thread
        self.totalUnreadCount = totalUnreadCount
        self.type = type
        self.unreadChannels = unreadChannels
        self.unreadThreads = unreadThreads
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case cid
        case createdAt = "created_at"
        case groupedUnreadChannels = "grouped_unread_channels"
        case lastReadMessageId = "last_read_message_id"
        case thread
        case totalUnreadCount = "total_unread_count"
        case type
        case unreadChannels = "unread_channels"
        case unreadThreads = "unread_threads"
        case user
    }
}
