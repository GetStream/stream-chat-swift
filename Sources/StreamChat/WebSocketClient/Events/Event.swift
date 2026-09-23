//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Event {
    var name: String {
        String(describing: Self.self).replacingOccurrences(of: "DTO", with: "")
    }
}

/// An internal protocol marking the generated v2 event models the SDK understands. Conformance is opt-in,
/// one `extension XEventDTO: EventDTO` per handled event type.
protocol EventDTO: Event {
    /// Converts event DTO to event with evaluated models.
    ///
    /// If some model is missing in database `nil` is returned.
    ///
    /// - Parameter session: The database session used to load event models from database.
    func toDomainEvent(session: DatabaseSession) -> Event?
}

extension WSEvent: @unchecked Sendable, Event {
    func healthcheck() -> HealthCheckInfo? {
        guard case .typeHealthCheckEvent(let event) = self else { return nil }
        return HealthCheckInfo(connectionId: event.connectionId)
    }

    func error() -> (any Error)? {
        nil
    }

    var createdAt: Date {
        switch self {
        case let .typeAIIndicatorClearEvent(value):
            return value.createdAt
        case let .typeAIIndicatorStopEvent(value):
            return value.createdAt
        case let .typeAIIndicatorUpdateEvent(value):
            return value.createdAt
        case let .typeChannelDeletedEvent(value):
            return value.createdAt
        case let .typeChannelHiddenEvent(value):
            return value.createdAt
        case let .typeChannelTruncatedEvent(value):
            return value.createdAt
        case let .typeChannelUpdatedEvent(value):
            return value.createdAt
        case let .typeChannelVisibleEvent(value):
            return value.createdAt
        case let .typeDraftDeletedEvent(value):
            return value.createdAt
        case let .typeDraftUpdatedEvent(value):
            return value.createdAt
        case let .typeHealthCheckEvent(value):
            return value.createdAt
        case let .typeMemberAddedEvent(value):
            return value.createdAt
        case let .typeMemberRemovedEvent(value):
            return value.createdAt
        case let .typeMemberUpdatedEvent(value):
            return value.createdAt
        case let .typeMessageDeletedEvent(value):
            return value.createdAt
        case let .typeMessageDeliveredEvent(value):
            return value.createdAt
        case let .typeMessageNewEvent(value):
            return value.createdAt
        case let .typeMessageReadEvent(value):
            return value.createdAt
        case let .typeMessageUpdatedEvent(value):
            return value.createdAt
        case let .typeNotificationAddedToChannelEvent(value):
            return value.createdAt
        case let .typeNotificationChannelDeletedEvent(value):
            return value.createdAt
        case let .typeNotificationChannelMutesUpdatedEvent(value):
            return value.createdAt
        case let .typeNotificationInviteAcceptedEvent(value):
            return value.createdAt
        case let .typeNotificationInviteRejectedEvent(value):
            return value.createdAt
        case let .typeNotificationInvitedEvent(value):
            return value.createdAt
        case let .typeNotificationMarkReadEvent(value):
            return value.createdAt
        case let .typeNotificationMarkUnreadEvent(value):
            return value.createdAt
        case let .typeNotificationNewMessageEvent(value):
            return value.createdAt
        case let .typeNotificationMutesUpdatedEvent(value):
            return value.createdAt
        case let .typeReminderNotificationEvent(value):
            return value.createdAt
        case let .typeNotificationRemovedFromChannelEvent(value):
            return value.createdAt
        case let .typeNotificationThreadMessageNewEvent(value):
            return value.createdAt
        case let .typePollClosedEvent(value):
            return value.createdAt
        case let .typePollDeletedEvent(value):
            return value.createdAt
        case let .typePollUpdatedEvent(value):
            return value.createdAt
        case let .typePollVoteCastedEvent(value):
            return value.createdAt
        case let .typePollVoteChangedEvent(value):
            return value.createdAt
        case let .typePollVoteRemovedEvent(value):
            return value.createdAt
        case let .typeReactionDeletedEvent(value):
            return value.createdAt
        case let .typeReactionNewEvent(value):
            return value.createdAt
        case let .typeReactionUpdatedEvent(value):
            return value.createdAt
        case let .typeReminderCreatedEvent(value):
            return value.createdAt
        case let .typeReminderDeletedEvent(value):
            return value.createdAt
        case let .typeReminderUpdatedEvent(value):
            return value.createdAt
        case let .typeThreadUpdatedEvent(value):
            return value.createdAt
        case let .typeTypingStartEvent(value):
            return value.createdAt
        case let .typeTypingStopEvent(value):
            return value.createdAt
        case let .typeUserBannedEvent(value):
            return value.createdAt
        case let .typeUserMessagesDeletedEvent(value):
            return value.createdAt
        case let .typeUserPresenceChangedEvent(value):
            return value.createdAt
        case let .typeUserUnbannedEvent(value):
            return value.createdAt
        case let .typeUserUpdatedEvent(value):
            return value.createdAt
        case let .typeUserWatchingStartEvent(value):
            return value.createdAt
        case let .typeUserWatchingStopEvent(value):
            return value.createdAt
        }
    }
}

/// A protocol for any `ChannelEvent` where it has a  `channel` payload.
protocol ChannelSpecificEvent: Event {
    var cid: ChannelId { get }
}

/// A bounding protocol for all events that have unread counts.
public protocol HasUnreadCount: Event {
    /// If `ReadEvents` options is disabled the value is always `nil`.
    var unreadCount: UnreadCount? { get }
}

/// A protocol for events that carry unread channel counts keyed by group.
public protocol HasUnreadChannelCountsByGroup: Event {
    /// Unread channel counts keyed by the backend-provided group identifier.
    var unreadChannelCountsByGroup: [String: Int]? { get }
}

/// A protocol for any `MemberEvent` where it has a `member`, and `channel` payload.
public protocol MemberEvent: Event {
    var cid: ChannelId { get }
}

/// A protocol custom event payload must conform to.
public protocol CustomEventPayload: Codable, Hashable, Sendable {
    /// A type all events holding this payload have.
    static var eventType: EventType { get }
}
