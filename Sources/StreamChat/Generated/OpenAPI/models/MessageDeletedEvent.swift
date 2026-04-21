//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageDeletedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var channelCustom: [String: RawJSON]?
    /// The ID of the channel where the message was sent
    var channelId: String?
    /// The number of members in the channel
    var channelMemberCount: Int?
    /// The number of messages in the channel
    var channelMessageCount: Int?
    /// The type of the channel where the message was sent
    var channelType: String?
    /// The CID of the channel where the message was sent
    var cid: String?
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    /// Whether the message was deleted only for the current user
    var deletedForMe: Bool?
    /// Whether the message was hard deleted
    var hardDelete: Bool
    var message: MessageResponse
    var messageId: String
    var receivedAt: Date?
    /// The team ID
    var team: String?
    /// The type of event: "message.deleted" in this case
    var type: String = "message.deleted"
    var user: UserResponseCommonFields?

    init(channelCustom: [String: RawJSON]? = nil, channelId: String? = nil, channelMemberCount: Int? = nil, channelMessageCount: Int? = nil, channelType: String? = nil, cid: String? = nil, createdAt: Date, custom: [String: RawJSON], deletedForMe: Bool? = nil, hardDelete: Bool, message: MessageResponse, messageId: String, receivedAt: Date? = nil, team: String? = nil, user: UserResponseCommonFields? = nil) {
        self.channelCustom = channelCustom
        self.channelId = channelId
        self.channelMemberCount = channelMemberCount
        self.channelMessageCount = channelMessageCount
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.deletedForMe = deletedForMe
        self.hardDelete = hardDelete
        self.message = message
        self.messageId = messageId
        self.receivedAt = receivedAt
        self.team = team
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCustom = "channel_custom"
        case channelId = "channel_id"
        case channelMemberCount = "channel_member_count"
        case channelMessageCount = "channel_message_count"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case custom
        case deletedForMe = "deleted_for_me"
        case hardDelete = "hard_delete"
        case message
        case messageId = "message_id"
        case receivedAt = "received_at"
        case team
        case type
        case user
    }

    static func == (lhs: MessageDeletedEvent, rhs: MessageDeletedEvent) -> Bool {
        lhs.channelCustom == rhs.channelCustom &&
            lhs.channelId == rhs.channelId &&
            lhs.channelMemberCount == rhs.channelMemberCount &&
            lhs.channelMessageCount == rhs.channelMessageCount &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.deletedForMe == rhs.deletedForMe &&
            lhs.hardDelete == rhs.hardDelete &&
            lhs.message == rhs.message &&
            lhs.messageId == rhs.messageId &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.team == rhs.team &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelCustom)
        hasher.combine(channelId)
        hasher.combine(channelMemberCount)
        hasher.combine(channelMessageCount)
        hasher.combine(channelType)
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(deletedForMe)
        hasher.combine(hardDelete)
        hasher.combine(message)
        hasher.combine(messageId)
        hasher.combine(receivedAt)
        hasher.combine(team)
        hasher.combine(type)
        hasher.combine(user)
    }
}
