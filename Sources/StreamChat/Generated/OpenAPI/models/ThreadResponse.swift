//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ThreadResponse: Sendable, Decodable {
    /// Active Participant Count
    let activeParticipantCount: Int?
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
    /// Deleted At
    let deletedAt: Date?
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
    /// Thread Participants
    let threadParticipants: [ThreadParticipantPayload]?
    /// Title
    let title: String
    /// Date/time of the last update
    let updatedAt: Date

    init(
        activeParticipantCount: Int? = nil,
        channel: ChannelDetailPayload? = nil,
        channelCid: String,
        createdAt: Date,
        createdBy: UserPayload? = nil,
        createdByUserId: String? = nil,
        custom: [String: RawJSON],
        deletedAt: Date? = nil,
        lastMessageAt: Date? = nil,
        parentMessage: MessageResponse? = nil,
        parentMessageId: String,
        participantCount: Int,
        replyCount: Int,
        threadParticipants: [ThreadParticipantPayload]? = nil,
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
        self.deletedAt = deletedAt
        self.lastMessageAt = lastMessageAt
        self.parentMessage = parentMessage
        self.parentMessageId = parentMessageId
        self.participantCount = participantCount
        self.replyCount = replyCount
        self.threadParticipants = threadParticipants
        self.title = title
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case activeParticipantCount = "active_participant_count"
        case channel
        case channelCid = "channel_cid"
        case createdAt = "created_at"
        case createdBy = "created_by"
        case createdByUserId = "created_by_user_id"
        case custom
        case deletedAt = "deleted_at"
        case lastMessageAt = "last_message_at"
        case parentMessage = "parent_message"
        case parentMessageId = "parent_message_id"
        case participantCount = "participant_count"
        case replyCount = "reply_count"
        case threadParticipants = "thread_participants"
        case title
        case updatedAt = "updated_at"
    }

    class var customExcludedKeys: Set<String> {
        Set(CodingKeys.allCases.map(\.rawValue))
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activeParticipantCount = try container.decodeIfPresent(
            Int.self,
            forKey: .activeParticipantCount
        )
        channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        channelCid = try container.decode(String.self, forKey: .channelCid)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        createdBy = try container.decodeIfPresent(UserPayload.self, forKey: .createdBy)
        createdByUserId = try container.decodeIfPresent(String.self, forKey: .createdByUserId)
        if let decoded = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) {
            custom = decoded
        } else {
            var flattened = try [String: RawJSON](from: decoder)
            flattened.removeValues(forKeys: Array(Self.customExcludedKeys))
            custom = flattened
        }
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        lastMessageAt = try container.decodeIfPresent(Date.self, forKey: .lastMessageAt)
        parentMessage = try container.decodeIfPresent(MessageResponse.self, forKey: .parentMessage)
        parentMessageId = try container.decode(String.self, forKey: .parentMessageId)
        participantCount = try container.decode(Int.self, forKey: .participantCount)
        replyCount = try container.decode(Int.self, forKey: .replyCount)
        threadParticipants = try container.decodeIfPresent(
            [ThreadParticipantPayload].self,
            forKey: .threadParticipants
        )
        title = try container.decode(String.self, forKey: .title)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
