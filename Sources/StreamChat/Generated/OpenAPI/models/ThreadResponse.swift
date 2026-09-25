//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ThreadResponse: Sendable, Decodable {
    /// Active Participant Count
    let activeParticipantCount: Int
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    /// Date/time of creation
    let createdAt: Date
    /// User response object
    let createdBy: UserPayload?
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
        createdAt: Date,
        createdBy: UserPayload? = nil,
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
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.custom = custom
        self.lastMessageAt = lastMessageAt
        self.parentMessage = parentMessage
        self.parentMessageId = parentMessageId
        self.participantCount = participantCount
        self.replyCount = replyCount
        self.title = title
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case activeParticipantCount = "active_participant_count"
        case channel
        case createdAt = "created_at"
        case createdBy = "created_by"
        case custom
        case lastMessageAt = "last_message_at"
        case parentMessage = "parent_message"
        case parentMessageId = "parent_message_id"
        case participantCount = "participant_count"
        case replyCount = "reply_count"
        case title
        case updatedAt = "updated_at"
    }
}
