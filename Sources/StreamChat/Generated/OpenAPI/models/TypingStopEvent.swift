//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class TypingStopEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    /// The ID of the channel where the user stopped typing
    var channelId: String?
    /// The type of the channel where the user stopped typing
    var channelType: String?
    /// The CID of the channel where the user stopped typing
    var cid: String?
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    /// The parent ID if the user stopped typing in a thread
    var parentId: String?
    var receivedAt: Date?
    /// The type of event: "typing.stop" in this case
    var type: String = "typing.stop"
    var user: UserResponseCommonFields?

    init(channelId: String? = nil, channelType: String? = nil, cid: String? = nil, createdAt: Date, custom: [String: RawJSON], parentId: String? = nil, receivedAt: Date? = nil, user: UserResponseCommonFields? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.parentId = parentId
        self.receivedAt = receivedAt
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case custom
        case parentId = "parent_id"
        case receivedAt = "received_at"
        case type
        case user
    }

    static func == (lhs: TypingStopEvent, rhs: TypingStopEvent) -> Bool {
        lhs.channelId == rhs.channelId &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.parentId == rhs.parentId &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelId)
        hasher.combine(channelType)
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(parentId)
        hasher.combine(receivedAt)
        hasher.combine(type)
        hasher.combine(user)
    }
}
