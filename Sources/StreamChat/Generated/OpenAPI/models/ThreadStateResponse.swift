//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ThreadStateResponse: Sendable, Decodable {
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
    let draft: DraftPayload?
    /// Last Message At
    let lastMessageAt: Date?
    let latestReplies: [MessageResponse]
    /// Represents any chat message
    let parentMessage: MessageResponse?
    /// Parent Message ID
    let parentMessageId: String
    /// Participant Count
    let participantCount: Int
    let read: [ReadStateResponse]?
    /// Reply Count
    let replyCount: Int
    /// Thread Participants
    let threadParticipants: [ThreadParticipantPayload]?
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
        draft: DraftPayload? = nil,
        lastMessageAt: Date? = nil,
        latestReplies: [MessageResponse],
        parentMessage: MessageResponse? = nil,
        parentMessageId: String,
        participantCount: Int,
        read: [ReadStateResponse]? = nil,
        replyCount: Int,
        threadParticipants: [ThreadParticipantPayload]? = nil,
        title: String,
        updatedAt: Date
    ) {
        self.activeParticipantCount = activeParticipantCount
        self.channel = channel
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.custom = custom
        self.draft = draft
        self.lastMessageAt = lastMessageAt
        self.latestReplies = latestReplies
        self.parentMessage = parentMessage
        self.parentMessageId = parentMessageId
        self.participantCount = participantCount
        self.read = read
        self.replyCount = replyCount
        self.threadParticipants = threadParticipants
        self.title = title
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case activeParticipantCount = "active_participant_count"
        case channel
        case createdAt = "created_at"
        case createdBy = "created_by"
        case custom
        case draft
        case lastMessageAt = "last_message_at"
        case latestReplies = "latest_replies"
        case parentMessage = "parent_message"
        case parentMessageId = "parent_message_id"
        case participantCount = "participant_count"
        case read
        case replyCount = "reply_count"
        case threadParticipants = "thread_participants"
        case title
        case updatedAt = "updated_at"
    }
}
