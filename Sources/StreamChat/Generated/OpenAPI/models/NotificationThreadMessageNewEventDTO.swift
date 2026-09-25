//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class NotificationThreadMessageNewEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    let channelMessageCount: Int?
    /// The CID of the channel where the message was sent
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    /// Represents any chat message
    let message: MessageResponse
    /// The type of event: "notification.message_new" in this case
    let type: String
    let unreadThreads: Int?

    init(
        channel: ChannelDetailPayload,
        channelMessageCount: Int? = nil,
        cid: ChannelId,
        createdAt: Date,
        message: MessageResponse,
        type: String = "notification.thread_message_new",
        unreadThreads: Int? = nil
    ) {
        self.channel = channel
        self.channelMessageCount = channelMessageCount
        self.cid = cid
        self.createdAt = createdAt
        self.message = message
        self.type = type
        self.unreadThreads = unreadThreads
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case channelMessageCount = "channel_message_count"
        case cid
        case createdAt = "created_at"
        case message
        case type
        case unreadThreads = "unread_threads"
    }
}
