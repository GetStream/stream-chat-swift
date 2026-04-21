//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ThreadStateResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Active Participant Count
    var activeParticipantCount: Int
    var channel: ChannelResponse?
    /// Channel CID
    var channelCid: String
    /// Date/time of creation
    var createdAt: Date
    var createdBy: UserResponse?
    /// Created By User ID
    var createdByUserId: String
    /// Custom data for this object
    var custom: [String: RawJSON]
    /// Deleted At
    var deletedAt: Date?
    var draft: DraftResponse?
    /// Last Message At
    var lastMessageAt: Date?
    var latestReplies: [MessageResponse]
    var parentMessage: MessageResponse?
    /// Parent Message ID
    var parentMessageId: String
    /// Participant Count
    var participantCount: Int
    var read: [ReadStateResponse]?
    /// Reply Count
    var replyCount: Int?
    /// Thread Participants
    var threadParticipants: [ThreadParticipantModel]?
    /// Title
    var title: String
    /// Date/time of the last update
    var updatedAt: Date

    init(activeParticipantCount: Int, channel: ChannelResponse? = nil, channelCid: String, createdAt: Date, createdBy: UserResponse? = nil, createdByUserId: String, custom: [String: RawJSON], deletedAt: Date? = nil, draft: DraftResponse? = nil, lastMessageAt: Date? = nil, latestReplies: [MessageResponse], parentMessage: MessageResponse? = nil, parentMessageId: String, participantCount: Int, read: [ReadStateResponse]? = nil, replyCount: Int? = nil, threadParticipants: [ThreadParticipantModel]? = nil, title: String, updatedAt: Date) {
        self.activeParticipantCount = activeParticipantCount
        self.channel = channel
        self.channelCid = channelCid
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.createdByUserId = createdByUserId
        self.custom = custom
        self.deletedAt = deletedAt
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
        case channelCid = "channel_cid"
        case createdAt = "created_at"
        case createdBy = "created_by"
        case createdByUserId = "created_by_user_id"
        case custom
        case deletedAt = "deleted_at"
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

    static func == (lhs: ThreadStateResponse, rhs: ThreadStateResponse) -> Bool {
        lhs.activeParticipantCount == rhs.activeParticipantCount &&
            lhs.channel == rhs.channel &&
            lhs.channelCid == rhs.channelCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.createdBy == rhs.createdBy &&
            lhs.createdByUserId == rhs.createdByUserId &&
            lhs.custom == rhs.custom &&
            lhs.deletedAt == rhs.deletedAt &&
            lhs.draft == rhs.draft &&
            lhs.lastMessageAt == rhs.lastMessageAt &&
            lhs.latestReplies == rhs.latestReplies &&
            lhs.parentMessage == rhs.parentMessage &&
            lhs.parentMessageId == rhs.parentMessageId &&
            lhs.participantCount == rhs.participantCount &&
            lhs.read == rhs.read &&
            lhs.replyCount == rhs.replyCount &&
            lhs.threadParticipants == rhs.threadParticipants &&
            lhs.title == rhs.title &&
            lhs.updatedAt == rhs.updatedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(activeParticipantCount)
        hasher.combine(channel)
        hasher.combine(channelCid)
        hasher.combine(createdAt)
        hasher.combine(createdBy)
        hasher.combine(createdByUserId)
        hasher.combine(custom)
        hasher.combine(deletedAt)
        hasher.combine(draft)
        hasher.combine(lastMessageAt)
        hasher.combine(latestReplies)
        hasher.combine(parentMessage)
        hasher.combine(parentMessageId)
        hasher.combine(participantCount)
        hasher.combine(read)
        hasher.combine(replyCount)
        hasher.combine(threadParticipants)
        hasher.combine(title)
        hasher.combine(updatedAt)
    }
}
