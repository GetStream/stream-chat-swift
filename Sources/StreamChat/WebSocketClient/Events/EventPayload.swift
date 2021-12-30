//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - Temporary

/// The DTO object mirroring the JSON representation of an event.
class EventPayload: Decodable {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case eventType = "type"
        case connectionId = "connection_id"
        case cid
        case channelType = "channel_type"
        case channelId = "channel_id"
        case currentUser = "me"
        case user
        case createdBy = "created_by"
        case memberContainer = "member"
        case channel
        case message
        case reaction
        case watcherCount = "watcher_count"
        case createdAt = "created_at"
        case isChannelHistoryCleared = "clear_history"
        case banReason = "reason"
        case banExpiredAt = "expiration"
        case parentId = "parent_id"
        case hardDelete = "hard_delete"
    }
    
    let eventType: EventType
    let connectionId: String?
    let cid: ChannelId?
    let currentUser: CurrentUserPayload?
    let user: UserPayload?
    let createdBy: UserPayload?
    let memberContainer: MemberContainerPayload?
    let channel: ChannelDetailPayload?
    let message: MessagePayload?
    let reaction: MessageReactionPayload?
    let watcherCount: Int?
    let unreadCount: UnreadCount?
    let createdAt: Date?
    let isChannelHistoryCleared: Bool?
    let banReason: String?
    let banExpiredAt: Date?
    let parentId: MessageId?
    let hardDelete: Bool

    init(
        eventType: EventType,
        connectionId: String? = nil,
        cid: ChannelId? = nil,
        currentUser: CurrentUserPayload? = nil,
        user: UserPayload? = nil,
        createdBy: UserPayload? = nil,
        memberContainer: MemberContainerPayload? = nil,
        channel: ChannelDetailPayload? = nil,
        message: MessagePayload? = nil,
        reaction: MessageReactionPayload? = nil,
        watcherCount: Int? = nil,
        unreadCount: UnreadCount? = nil,
        createdAt: Date? = nil,
        isChannelHistoryCleared: Bool? = nil,
        banReason: String? = nil,
        banExpiredAt: Date? = nil,
        parentId: MessageId? = nil,
        hardDelete: Bool = false
    ) {
        self.eventType = eventType
        self.connectionId = connectionId
        self.cid = cid
        self.currentUser = currentUser
        self.user = user
        self.createdBy = createdBy
        self.memberContainer = memberContainer
        self.channel = channel
        self.message = message
        self.reaction = reaction
        self.watcherCount = watcherCount
        self.unreadCount = unreadCount
        self.createdAt = createdAt
        self.isChannelHistoryCleared = isChannelHistoryCleared
        self.banReason = banReason
        self.banExpiredAt = banExpiredAt
        self.parentId = parentId
        self.hardDelete = hardDelete
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        eventType = try container.decode(EventType.self, forKey: .eventType)
        connectionId = try container.decodeIfPresent(String.self, forKey: .connectionId)
        // In healthCheck event we can receive invalid id containing "*".
        // We don't need to throw error in that case and can treat it like missing cid.
        cid = try? container.decodeIfPresent(ChannelId.self, forKey: .cid)
        currentUser = try container.decodeIfPresent(CurrentUserPayload.self, forKey: .currentUser)
        user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
        createdBy = try container.decodeIfPresent(UserPayload.self, forKey: .createdBy)
        memberContainer = try container.decodeIfPresent(MemberContainerPayload.self, forKey: .memberContainer)
        channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        message = try container.decodeIfPresent(MessagePayload.self, forKey: .message)
        reaction = try container.decodeIfPresent(MessageReactionPayload.self, forKey: .reaction)
        watcherCount = try container.decodeIfPresent(Int.self, forKey: .watcherCount)
        unreadCount = try? UnreadCount(from: decoder)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        isChannelHistoryCleared = try container.decodeIfPresent(Bool.self, forKey: .isChannelHistoryCleared)
        banReason = try container.decodeIfPresent(String.self, forKey: .banReason)
        banExpiredAt = try container.decodeIfPresent(Date.self, forKey: .banExpiredAt)
        parentId = try container.decodeIfPresent(MessageId.self, forKey: .parentId)
        hardDelete = try container.decodeIfPresent(Bool.self, forKey: .hardDelete) ?? false
    }
    
    func event() throws -> Event {
        try eventType.event(from: self)
    }
}

extension EventPayload {
    /// Get an unwrapped value from the payload or throw an error.
    func value<Value>(at keyPath: KeyPath<EventPayload, Value?>) throws -> Value {
        guard let value = self[keyPath: keyPath] else {
            throw ClientError.EventDecoding(missingValue: String(describing: keyPath), for: Self.self)
        }
        
        return value
    }
}
