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
    var createdAt: Date { get }
    var eventChannel: ChannelDetailPayload? { get }
    var eventChannelMessageCount: Int? { get }
    var eventCID: ChannelId? { get }
    var eventCurrentUser: OwnUserResponse? { get }
    var eventGroupedUnreadChannels: [String: Int]? { get }
    var eventMessage: MessageResponse? { get }
    var eventPoll: PollPayload? { get }
    var eventThread: ThreadResponse? { get }
    var eventUnreadCount: UnreadCountPayload? { get }
    var eventUser: UserPayload? { get }

    /// Converts event DTO to event with evaluated models.
    ///
    /// If some model is missing in database `nil` is returned.
    ///
    /// - Parameter session: The database session used to load event models from database.
    func toDomainEvent(session: DatabaseSession) -> Event?
}

extension EventDTO {
    var eventChannel: ChannelDetailPayload? { nil }
    var eventChannelMessageCount: Int? { nil }
    var eventCID: ChannelId? { eventChannel?.cid }
    var eventCurrentUser: OwnUserResponse? { nil }
    var eventGroupedUnreadChannels: [String: Int]? { nil }
    var eventMessage: MessageResponse? { nil }
    var eventPoll: PollPayload? { nil }
    var eventThread: ThreadResponse? { nil }
    var eventUnreadCount: UnreadCountPayload? { nil }
    var eventUser: UserPayload? { nil }
}

extension ChannelDeletedEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventUser: UserPayload? { user }
}

extension ChannelHiddenEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventUser: UserPayload? { user }
}

extension ChannelTruncatedEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventChannelMessageCount: Int? { channelMessageCount }
    var eventCID: ChannelId? { channel.cid }
    var eventMessage: MessageResponse? { message }
    var eventUser: UserPayload? { user }
}

extension ChannelUpdatedEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventChannelMessageCount: Int? { channelMessageCount }
    var eventCID: ChannelId? { channel.cid }
    var eventMessage: MessageResponse? { message }
    var eventUser: UserPayload? { user }
}

extension ChannelVisibleEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventUser: UserPayload? { user }
}

extension HealthCheckEventDTO {
    var eventCurrentUser: OwnUserResponse? { me }
}

extension MemberAddedEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventUser: UserPayload? { user }
}

extension MemberRemovedEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventUser: UserPayload? { user }
}

extension MemberUpdatedEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventUser: UserPayload? { user }
}

extension MessageDeletedEventDTO {
    var eventChannelMessageCount: Int? { channelMessageCount }
    var eventCID: ChannelId? { cid }
    var eventMessage: MessageResponse? { message }
    var eventUser: UserPayload? { user }
}

extension MessageDeliveredEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventUser: UserPayload? { user }
}

extension MessageNewEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventChannelMessageCount: Int? { channelMessageCount }
    var eventCID: ChannelId? { cid }
    var eventGroupedUnreadChannels: [String: Int]? { groupedUnreadChannels }
    var eventMessage: MessageResponse? { message }
    var eventUnreadCount: UnreadCountPayload? {
        .init(channels: unreadChannels, messages: totalUnreadCount, threads: nil)
    }

    var eventUser: UserPayload? { user }
}

extension MessageReadEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventThread: ThreadResponse? { thread }
    var eventUser: UserPayload? { user }
}

extension MessageUpdatedEventDTO {
    var eventChannelMessageCount: Int? { channelMessageCount }
    var eventCID: ChannelId? { cid }
    var eventMessage: MessageResponse? { message }
    var eventUser: UserPayload? { user }
}

extension NotificationAddedToChannelEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
}

extension NotificationChannelDeletedEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventGroupedUnreadChannels: [String: Int]? { groupedUnreadChannels }
    var eventUnreadCount: UnreadCountPayload? {
        .init(channels: unreadChannels, messages: totalUnreadCount, threads: nil)
    }
}

extension NotificationChannelMutesUpdatedEventDTO {
    var eventCurrentUser: OwnUserResponse? { me }
}

extension NotificationInviteAcceptedEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventUser: UserPayload? { user }
}

extension NotificationInvitedEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventUser: UserPayload? { user }
}

extension NotificationInviteRejectedEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventUser: UserPayload? { user }
}

extension NotificationMarkReadEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventGroupedUnreadChannels: [String: Int]? { groupedUnreadChannels }
    var eventThread: ThreadResponse? { thread }
    var eventUnreadCount: UnreadCountPayload? {
        .init(channels: unreadChannels, messages: totalUnreadCount, threads: unreadThreads)
    }

    var eventUser: UserPayload? { user }
}

extension NotificationMarkUnreadEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventGroupedUnreadChannels: [String: Int]? { groupedUnreadChannels }
    var eventUnreadCount: UnreadCountPayload? {
        .init(channels: unreadChannels, messages: totalUnreadCount, threads: unreadThreads)
    }

    var eventUser: UserPayload? { user }
}

extension NotificationMutesUpdatedEventDTO {
    var eventCurrentUser: OwnUserResponse? { me }
}

extension NotificationNewMessageEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventChannelMessageCount: Int? { channelMessageCount }
    var eventCID: ChannelId? { channel.cid }
    var eventGroupedUnreadChannels: [String: Int]? { groupedUnreadChannels }
    var eventMessage: MessageResponse? { message }
    var eventUnreadCount: UnreadCountPayload? {
        .init(channels: unreadChannels, messages: totalUnreadCount, threads: nil)
    }
}

extension NotificationRemovedFromChannelEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventUser: UserPayload? { user }
}

extension NotificationThreadMessageNewEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventChannelMessageCount: Int? { channelMessageCount }
    var eventCID: ChannelId? { cid }
    var eventMessage: MessageResponse? { message }
    var eventUnreadCount: UnreadCountPayload? {
        .init(channels: nil, messages: nil, threads: unreadThreads)
    }
}

extension PollClosedEventDTO {
    var eventPoll: PollPayload? { poll }
}

extension PollDeletedEventDTO {
    var eventPoll: PollPayload? { poll }
}

extension PollUpdatedEventDTO {
    var eventPoll: PollPayload? { poll }
}

extension PollVoteCastedEventDTO {
    var eventPoll: PollPayload? { poll }
}

extension PollVoteChangedEventDTO {
    var eventPoll: PollPayload? { poll }
}

extension PollVoteRemovedEventDTO {
    var eventPoll: PollPayload? { poll }
}

extension ReactionDeletedEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventChannelMessageCount: Int? { channelMessageCount }
    var eventCID: ChannelId? { cid }
    var eventMessage: MessageResponse? { message }
    var eventUser: UserPayload? { user }
}

extension ReactionNewEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventChannelMessageCount: Int? { channelMessageCount }
    var eventCID: ChannelId? { cid }
    var eventMessage: MessageResponse? { message }
    var eventUser: UserPayload? { user }
}

extension ReactionUpdatedEventDTO {
    var eventChannel: ChannelDetailPayload? { channel }
    var eventChannelMessageCount: Int? { channelMessageCount }
    var eventCID: ChannelId? { cid }
    var eventMessage: MessageResponse? { message }
    var eventUser: UserPayload? { user }
}

extension ThreadUpdatedEventDTO {
    var eventThread: ThreadResponse? { thread }
}

extension TypingStartEventDTO {
    var eventUser: UserPayload? { user }
}

extension TypingStopEventDTO {
    var eventUser: UserPayload? { user }
}

extension UserBannedEventDTO {
    var eventUser: UserPayload? { user }
}

extension UserMessagesDeletedEventDTO {
    var eventUser: UserPayload? { user }
}

extension UserPresenceChangedEventDTO {
    var eventUser: UserPayload? { user }
}

extension UserUnbannedEventDTO {
    var eventUser: UserPayload? { user }
}

extension UserUpdatedEventDTO {
    var eventUser: UserPayload? { user }
}

extension UserWatchingStartEventDTO {
    var eventUser: UserPayload? { user }
}

extension UserWatchingStopEventDTO {
    var eventUser: UserPayload? { user }
}

extension WSEvent: @unchecked Sendable, Event {
    func healthcheck() -> HealthCheckInfo? {
        guard case .typeHealthCheckEvent(let event) = self else { return nil }
        return HealthCheckInfo(connectionId: event.connectionId)
    }

    func error() -> (any Error)? {
        nil
    }

    var createdAt: Date { rawValue.createdAt }
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
