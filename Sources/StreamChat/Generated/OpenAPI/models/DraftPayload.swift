//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class DraftPayload: Sendable, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    let channelCid: String
    let createdAt: Date
    /// Contains the draft message content
    let message: DraftMessagePayload
    let parentId: String?
    /// Represents any chat message
    let parentMessage: MessageResponse?
    /// Represents any chat message
    let quotedMessage: MessageResponse?

    init(
        channel: ChannelDetailPayload? = nil,
        channelCid: String,
        createdAt: Date,
        message: DraftMessagePayload,
        parentId: String? = nil,
        parentMessage: MessageResponse? = nil,
        quotedMessage: MessageResponse? = nil
    ) {
        self.channel = channel
        self.channelCid = channelCid
        self.createdAt = createdAt
        self.message = message
        self.parentId = parentId
        self.parentMessage = parentMessage
        self.quotedMessage = quotedMessage
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case channelCid = "channel_cid"
        case createdAt = "created_at"
        case message
        case parentId = "parent_id"
        case parentMessage = "parent_message"
        case quotedMessage = "quoted_message"
    }
}
