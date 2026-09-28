//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case cid
        case createdAt = "created_at"
        case team
        case thread
        case type
        case user
    }
}
