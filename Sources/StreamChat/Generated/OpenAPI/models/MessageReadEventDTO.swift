//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a channel or thread is marked as read.
final class MessageReadEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    /// The CID of the channel where the message was read
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    /// The team ID
    let team: String?
    let thread: ThreadResponse?
    /// The type of event: "message.read" in this case
    let type: String
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload? = nil,
        cid: ChannelId,
        createdAt: Date,
        team: String? = nil,
        thread: ThreadResponse? = nil,
        type: String = "message.read",
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.cid = cid
        self.createdAt = createdAt
        self.team = team
        self.thread = thread
        self.type = type
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.team = try container.decodeIfPresent(String.self, forKey: .team)
        self.thread = try container.decodeIfPresent(ThreadResponse.self, forKey: .thread)
        self.type = try container.decode(String.self, forKey: .type)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
    }
}
