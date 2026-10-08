//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ThreadResponse: Sendable, Decodable {
    /// Active Participant Count
    let activeParticipantCount: Int
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    /// Channel CID
    let channelCid: String
    /// Date/time of creation
    let createdAt: Date
    /// User response object
    let createdBy: UserPayload?
    /// Created By User ID
    let createdByUserId: String?
    /// Custom data for this object
    let custom: [String: RawJSON]
    /// Last Message At
    let lastMessageAt: Date?
    /// Represents any chat message
    let parentMessage: MessageResponse?
    /// Parent Message ID
    let parentMessageId: String
    /// Participant Count
    let participantCount: Int
    /// Reply Count
    let replyCount: Int
    /// Title
    let title: String
    /// Date/time of the last update
    let updatedAt: Date

    init(
        activeParticipantCount: Int,
        channel: ChannelDetailPayload? = nil,
        channelCid: String,
        createdAt: Date,
        createdBy: UserPayload? = nil,
        createdByUserId: String? = nil,
        custom: [String: RawJSON],
        lastMessageAt: Date? = nil,
        parentMessage: MessageResponse? = nil,
        parentMessageId: String,
        participantCount: Int,
        replyCount: Int,
        title: String,
        updatedAt: Date
    ) {
        self.activeParticipantCount = activeParticipantCount
        self.channel = channel
        self.channelCid = channelCid
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.createdByUserId = createdByUserId
        self.custom = custom
        self.lastMessageAt = lastMessageAt
        self.parentMessage = parentMessage
        self.parentMessageId = parentMessageId
        self.participantCount = participantCount
        self.replyCount = replyCount
        self.title = title
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        activeParticipantCount = try container.decodeIfPresent(
            Int.self,
            forKey: .activeParticipantCount
        ) ?? 0
        channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        channelCid = try container.decode(String.self, forKey: .channelCid)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        createdBy = try container.decodeIfPresent(UserPayload.self, forKey: .createdBy)
        createdByUserId = try container.decodeIfPresent(String.self, forKey: .createdByUserId)
        custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) ?? [:]
        lastMessageAt = try container.decodeIfPresent(Date.self, forKey: .lastMessageAt)
        parentMessage = try container.decodeIfPresent(MessageResponse.self, forKey: .parentMessage)
        parentMessageId = try container.decode(String.self, forKey: .parentMessageId)
        participantCount = try container.decode(Int.self, forKey: .participantCount)
        replyCount = try container.decode(Int.self, forKey: .replyCount)
        title = try container.decode(String.self, forKey: .title)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
