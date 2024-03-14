//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Thread: Codable, Hashable {
    public var channelCid: String
    public var createdAt: Date
    public var parentMessageId: String
    public var title: String
    public var updatedAt: Date
    public var custom: [String: RawJSON]
    public var deletedAt: Date? = nil
    public var lastMessageAt: Date? = nil
    public var participantCount: Int? = nil
    public var replyCount: Int? = nil
    public var threadParticipants: [ThreadParticipant?]? = nil
    public var channel: Channel? = nil
    public var createdBy: UserObject? = nil
    public var parentMessage: Message? = nil

    public init(channelCid: String, createdAt: Date, parentMessageId: String, title: String, updatedAt: Date, custom: [String: RawJSON], deletedAt: Date? = nil, lastMessageAt: Date? = nil, participantCount: Int? = nil, replyCount: Int? = nil, threadParticipants: [ThreadParticipant?]? = nil, channel: Channel? = nil, createdBy: UserObject? = nil, parentMessage: Message? = nil) {
        self.channelCid = channelCid
        self.createdAt = createdAt
        self.parentMessageId = parentMessageId
        self.title = title
        self.updatedAt = updatedAt
        self.custom = custom
        self.deletedAt = deletedAt
        self.lastMessageAt = lastMessageAt
        self.participantCount = participantCount
        self.replyCount = replyCount
        self.threadParticipants = threadParticipants
        self.channel = channel
        self.createdBy = createdBy
        self.parentMessage = parentMessage
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCid = "channel_cid"
        case createdAt = "created_at"
        case parentMessageId = "parent_message_id"
        case title
        case updatedAt = "updated_at"
        case custom = "Custom"
        case deletedAt = "deleted_at"
        case lastMessageAt = "last_message_at"
        case participantCount = "participant_count"
        case replyCount = "reply_count"
        case threadParticipants = "thread_participants"
        case channel
        case createdBy = "created_by"
        case parentMessage = "parent_message"
    }
}