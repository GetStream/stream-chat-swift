//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a new message was sent to a thread.
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decode(ChannelDetailPayload.self, forKey: .channel)
        self.channelMessageCount = try container.decodeIfPresent(
            Int.self,
            forKey: .channelMessageCount
        )
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.message = try container.decode(MessageResponse.self, forKey: .message)
        self.type = try container.decode(String.self, forKey: .type)
        self.unreadThreads = try container.decodeIfPresent(Int.self, forKey: .unreadThreads)
    }
}
