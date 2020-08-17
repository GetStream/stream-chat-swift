//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - Temporary

public typealias ReactionType = String

struct ReactionPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case type
        case score
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    let type: ReactionType
    let score: Int
    let createdAt: Date
    let updatedAt: Date
}

// MARK: Temporary -

/// The DTO object mirroring the JSON representation of an event.
struct EventPayload<ExtraData: ExtraDataTypes>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case eventType = "type"
        case connectionId = "connection_id"
        case cid
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
    }
    
    let eventType: EventType
    let connectionId: String?
    let cid: ChannelId?
    let currentUser: CurrentUserPayload<ExtraData.User>?
    let user: UserPayload<ExtraData.User>?
    let createdBy: UserPayload<ExtraData.User>?
    let memberContainer: MemberContainerPayload<ExtraData.User>?
    let channel: ChannelDetailPayload<ExtraData>?
    let message: MessagePayload<ExtraData>?
    let reaction: ReactionPayload?
    let watcherCount: Int?
    let unreadCount: UnreadCount?
    let createdAt: Date?
    let isChannelHistoryCleared: Bool?
    let banReason: String?
    let banExpiredAt: Date?
    
    init(
        eventType: EventType,
        connectionId: String? = nil,
        cid: ChannelId? = nil,
        currentUser: CurrentUserPayload<ExtraData.User>? = nil,
        user: UserPayload<ExtraData.User>? = nil,
        createdBy: UserPayload<ExtraData.User>? = nil,
        memberContainer: MemberContainerPayload<ExtraData.User>? = nil,
        channel: ChannelDetailPayload<ExtraData>? = nil,
        message: MessagePayload<ExtraData>? = nil,
        reaction: ReactionPayload? = nil,
        watcherCount: Int? = nil,
        unreadCount: UnreadCount? = nil,
        createdAt: Date? = nil,
        isChannelHistoryCleared: Bool? = nil,
        banReason: String? = nil,
        banExpiredAt: Date? = nil
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
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        eventType = try container.decode(EventType.self, forKey: .eventType)
        connectionId = try container.decodeIfPresent(String.self, forKey: .connectionId)
        cid = try container.decodeIfPresent(ChannelId.self, forKey: .cid)
        currentUser = try container.decodeIfPresent(CurrentUserPayload<ExtraData.User>.self, forKey: .currentUser)
        user = try container.decodeIfPresent(UserPayload<ExtraData.User>.self, forKey: .user)
        createdBy = try container.decodeIfPresent(UserPayload<ExtraData.User>.self, forKey: .createdBy)
        memberContainer = try container.decodeIfPresent(MemberContainerPayload<ExtraData.User>.self, forKey: .memberContainer)
        channel = try container.decodeIfPresent(ChannelDetailPayload<ExtraData>.self, forKey: .channel)
        message = try container.decodeIfPresent(MessagePayload<ExtraData>.self, forKey: .message)
        reaction = try container.decodeIfPresent(ReactionPayload.self, forKey: .reaction)
        watcherCount = try container.decodeIfPresent(Int.self, forKey: .watcherCount)
        unreadCount = try? UnreadCount(from: decoder)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        isChannelHistoryCleared = try container.decodeIfPresent(Bool.self, forKey: .isChannelHistoryCleared)
        banReason = try container.decodeIfPresent(String.self, forKey: .banReason)
        banExpiredAt = try container.decodeIfPresent(Date.self, forKey: .banExpiredAt)
    }
    
    func event() throws -> Event {
        try eventType.event(from: self)
    }
}

extension EventPayload {
    /// Get an unwrapped value from the payload or throw an error.
    func value<Value>(at keyPath: KeyPath<EventPayload<ExtraData>, Value?>) throws -> Value {
        guard let value = self[keyPath: keyPath] else {
            throw ClientError.EventDecoding(missingValue: String(describing: keyPath), for: Self.self)
        }
        
        return value
    }
}
