//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
        case firstUnreadMessageId = "first_unread_message_id"
        case lastReadAt = "last_read_at"
        case lastReadMessageId = "last_read_message_id"
        case unreadMessagesCount = "unread_messages"
        case shadow
        case thread
        case vote = "poll_vote"
        case poll
        case aiState = "ai_state"
        case messageId = "message_id"
        case aiMessage = "ai_message"
        case draft
        case reminder
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
    let unreadCount: UnreadCountPayload?
    let createdAt: Date?
    let isChannelHistoryCleared: Bool?
    let banReason: String?
    let banExpiredAt: Date?
    let parentId: MessageId?
    let hardDelete: Bool
    let shadow: Bool?
    // Mark as unread properties
    let firstUnreadMessageId: MessageId?
    let lastReadMessageId: MessageId?
    let lastReadAt: Date?
    let unreadMessagesCount: Int?
    var poll: PollPayload?
    var vote: PollVotePayload?

    /// Thread Data, it is stored in Result, to be easier to debug decoding errors
    let threadDetails: Result<ThreadDetailsPayload, Error>?
    let threadPartial: Result<ThreadPartialPayload, Error>?
    
    let aiState: String?
    let messageId: String?
    let aiMessage: String?
    let draft: DraftPayload?
    let reminder: ReminderPayload?

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
        unreadCount: UnreadCountPayload? = nil,
        createdAt: Date? = nil,
        isChannelHistoryCleared: Bool? = nil,
        banReason: String? = nil,
        banExpiredAt: Date? = nil,
        parentId: MessageId? = nil,
        hardDelete: Bool = false,
        shadow: Bool? = nil,
        firstUnreadMessageId: MessageId? = nil,
        lastReadAt: Date? = nil,
        lastReadMessageId: MessageId? = nil,
        unreadMessagesCount: Int? = nil,
        threadDetails: Result<ThreadDetailsPayload, Error>? = nil,
        threadPartial: Result<ThreadPartialPayload, Error>? = nil,
        poll: PollPayload? = nil,
        vote: PollVotePayload? = nil,
        aiState: String? = nil,
        messageId: String? = nil,
        aiMessage: String? = nil,
        draft: DraftPayload? = nil,
        reminder: ReminderPayload? = nil
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
        self.shadow = shadow
        self.firstUnreadMessageId = firstUnreadMessageId
        self.lastReadAt = lastReadAt
        self.lastReadMessageId = lastReadMessageId
        self.unreadMessagesCount = unreadMessagesCount
        self.threadPartial = threadPartial
        self.threadDetails = threadDetails
        self.poll = poll
        self.vote = vote
        self.aiState = aiState
        self.messageId = messageId
        self.aiMessage = aiMessage
        self.draft = draft
        self.reminder = reminder
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
        channel = try? container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        message = try container.decodeIfPresent(MessagePayload.self, forKey: .message)
        reaction = try container.decodeIfPresent(MessageReactionPayload.self, forKey: .reaction)
        watcherCount = try container.decodeIfPresent(Int.self, forKey: .watcherCount)
        unreadCount = try? UnreadCountPayload(from: decoder)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        isChannelHistoryCleared = try container.decodeIfPresent(Bool.self, forKey: .isChannelHistoryCleared)
        banReason = try container.decodeIfPresent(String.self, forKey: .banReason)
        banExpiredAt = try container.decodeIfPresent(Date.self, forKey: .banExpiredAt)
        parentId = try container.decodeIfPresent(MessageId.self, forKey: .parentId)
        hardDelete = try container.decodeIfPresent(Bool.self, forKey: .hardDelete) ?? false
        shadow = try container.decodeIfPresent(Bool.self, forKey: .shadow)
        firstUnreadMessageId = try container.decodeIfPresent(MessageId.self, forKey: .firstUnreadMessageId)
        lastReadAt = try container.decodeIfPresent(Date.self, forKey: .lastReadAt)
        lastReadMessageId = try container.decodeIfPresent(MessageId.self, forKey: .lastReadMessageId)
        unreadMessagesCount = try container.decodeIfPresent(Int.self, forKey: .unreadMessagesCount)
        threadDetails = container.decodeAsResultIfPresent(ThreadDetailsPayload.self, forKey: .thread)
        threadPartial = container.decodeAsResultIfPresent(ThreadPartialPayload.self, forKey: .thread)
        vote = try container.decodeIfPresent(PollVotePayload.self, forKey: .vote)
        poll = try container.decodeIfPresent(PollPayload.self, forKey: .poll)
        aiState = try container.decodeIfPresent(String.self, forKey: .aiState)
        messageId = try container.decodeIfPresent(String.self, forKey: .messageId)
        aiMessage = try container.decodeIfPresent(String.self, forKey: .aiMessage)
        draft = try container.decodeIfPresent(DraftPayload.self, forKey: .draft)
        reminder = try container.decodeIfPresent(ReminderPayload.self, forKey: .reminder)
    }

    func event() throws -> Event {
        try eventType.event(from: self)
    }
}

/// Extension to make decoding error messages better.
/// The error message:
/// ```
/// `Swift.KeyPath<StreamChat.EventPayload, Swift.Optional<StreamChat.MemberPayload>>` field can't be `nil` for the `EventPayload` event.
/// ```
/// becomes:
/// ```
/// `memberContainer` field can't be `nil` for the `notification.added_to_channel` event.
/// ```
private extension PartialKeyPath where Root == EventPayload {
    var stringValue: String {
        switch self {
        case \EventPayload.eventType: return "eventType"
        case \EventPayload.connectionId: return "connectionId"
        case \EventPayload.cid: return "cid"
        case \EventPayload.currentUser: return "currentUser"
        case \EventPayload.user: return "user"
        case \EventPayload.createdBy: return "createdBy"
        case \EventPayload.memberContainer: return "memberContainer"
        case \EventPayload.channel: return "channel"
        case \EventPayload.message: return "message"
        case \EventPayload.reaction: return "reaction"
        case \EventPayload.watcherCount: return "watcherCount"
        case \EventPayload.unreadCount: return "unreadCount"
        case \EventPayload.createdAt: return "createdAt"
        case \EventPayload.isChannelHistoryCleared: return "isChannelHistoryCleared"
        case \EventPayload.banReason: return "banReason"
        case \EventPayload.banExpiredAt: return "banExpiredAt"
        case \EventPayload.parentId: return "parentId"
        case \EventPayload.hardDelete: return "hardDelete"
        case \EventPayload.shadow: return "shadow"
        case \EventPayload.threadPartial: return "thread"
        case \EventPayload.threadDetails: return "thread"
        default: return String(describing: self)
        }
    }
}

extension EventPayload {
    /// Get an unwrapped value from the payload or throw an error.
    func value<Value>(at keyPath: KeyPath<EventPayload, Value?>) throws -> Value {
        guard let value = self[keyPath: keyPath] else {
            throw ClientError.EventDecoding(missingValue: keyPath.stringValue, for: eventType)
        }

        return value
    }

    /// Get the value from the event payload and if it is a `Result` report the decoding error.
    func value<Value>(at keyPath: KeyPath<EventPayload, Result<Value, Error>?>) throws -> Value {
        guard let value = self[keyPath: keyPath] else {
            throw ClientError.EventDecoding(missingValue: keyPath.stringValue, for: eventType)
        }

        if let error = value.error {
            throw ClientError.EventDecoding(failedParsingValue: keyPath.stringValue, for: eventType, with: error)
        }

        return try value.get()
    }
}

extension Array where Element == EventPayload {
    /// Decodes events from event payloads. If decoding of some event fails the error is logged without interrupting the chain.
    ///
    /// - Returns: The array of successfully decoded events.
    func asEvents() -> [Event] {
        compactMap {
            do {
                return try $0.event()
            } catch {
                if error is ClientError.IgnoredEventType {
                    log.info("Skipping unsupported event type: \($0.eventType)")
                } else {
                    log.error("Failed to decode event from event payload: \($0), error: \(error)")
                }
                return nil
            }
        }
    }
}
