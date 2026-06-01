//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChatReminderResponseData: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channelCid: String
    var createdAt: Date
    var message: ChatMessageResponse?
    var messageId: String
    var remindAt: Date?
    var updatedAt: Date
    var user: UserResponse?
    var userId: String

    init(channelCid: String, createdAt: Date, message: ChatMessageResponse? = nil, messageId: String, remindAt: Date? = nil, updatedAt: Date, user: UserResponse? = nil, userId: String) {
        self.channelCid = channelCid
        self.createdAt = createdAt
        self.message = message
        self.messageId = messageId
        self.remindAt = remindAt
        self.updatedAt = updatedAt
        self.user = user
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCid = "channel_cid"
        case createdAt = "created_at"
        case message
        case messageId = "message_id"
        case remindAt = "remind_at"
        case updatedAt = "updated_at"
        case user
        case userId = "user_id"
    }

    static func == (lhs: ChatReminderResponseData, rhs: ChatReminderResponseData) -> Bool {
        lhs.channelCid == rhs.channelCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.message == rhs.message &&
            lhs.messageId == rhs.messageId &&
            lhs.remindAt == rhs.remindAt &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelCid)
        hasher.combine(createdAt)
        hasher.combine(message)
        hasher.combine(messageId)
        hasher.combine(remindAt)
        hasher.combine(updatedAt)
        hasher.combine(user)
        hasher.combine(userId)
    }
}
