//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        self.channelCid = try container.decode(String.self, forKey: .channelCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.message = try container.decode(DraftMessagePayload.self, forKey: .message)
        self.parentId = try container.decodeIfPresent(String.self, forKey: .parentId)
        self.parentMessage = try container.decodeIfPresent(
            MessageResponse.self,
            forKey: .parentMessage
        )
        self.quotedMessage = try container.decodeIfPresent(
            MessageResponse.self,
            forKey: .quotedMessage
        )
    }
}
