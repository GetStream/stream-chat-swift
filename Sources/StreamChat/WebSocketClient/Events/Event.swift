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

final class WSEventCommonData {
    let createdAt: Date
    let channel: ChannelDetailPayload?
    let channelMessageCount: Int?
    let cid: ChannelId?
    let currentUser: OwnUserResponse?
    let groupedUnreadChannels: [String: Int]?
    let message: MessageResponse?
    let poll: PollPayload?
    let thread: ThreadResponse?
    let unreadCount: UnreadCountPayload?
    let user: UserPayload?

    init(
        createdAt: Date,
        channel: ChannelDetailPayload? = nil,
        channelMessageCount: Int? = nil,
        cid: ChannelId? = nil,
        currentUser: OwnUserResponse? = nil,
        groupedUnreadChannels: [String: Int]? = nil,
        message: MessageResponse? = nil,
        poll: PollPayload? = nil,
        thread: ThreadResponse? = nil,
        unreadCount: UnreadCountPayload? = nil,
        user: UserPayload? = nil
    ) {
        self.createdAt = createdAt
        self.channel = channel
        self.channelMessageCount = channelMessageCount
        self.cid = cid ?? channel?.cid
        self.currentUser = currentUser
        self.groupedUnreadChannels = groupedUnreadChannels
        self.message = message
        self.poll = poll
        self.thread = thread
        self.unreadCount = unreadCount.flatMap {
            ($0.channels != nil && $0.messages != nil) || $0.threads != nil ? $0 : nil
        }
        self.user = user
    }
}

extension WSEvent: @unchecked Sendable, Event {
    func healthcheck() -> HealthCheckInfo? {
        guard case .typeHealthCheckEvent(let event) = self else { return nil }
        return HealthCheckInfo(connectionId: event.connectionId)
    }

    func error() -> (any Error)? {
        nil
    }

    var createdAt: Date { commonData.createdAt }

    var commonData: WSEventCommonData {
        switch self {
        case .typeAIIndicatorClearEvent(let event):
            return .init(createdAt: event.createdAt, cid: event.cid)
        case .typeAIIndicatorStopEvent(let event):
            return .init(createdAt: event.createdAt, cid: event.cid)
        case .typeAIIndicatorUpdateEvent(let event):
            return .init(createdAt: event.createdAt, cid: event.cid)
        case .typeChannelDeletedEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, user: event.user)
        case .typeChannelHiddenEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, cid: event.cid, user: event.user)
        case .typeChannelTruncatedEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, channelMessageCount: event.channelMessageCount, message: event.message, user: event.user)
        case .typeChannelUpdatedEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, channelMessageCount: event.channelMessageCount, message: event.message, user: event.user)
        case .typeChannelVisibleEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, cid: event.cid, user: event.user)
        case .typeDraftDeletedEvent(let event):
            return .init(createdAt: event.createdAt, cid: event.cid)
        case .typeDraftUpdatedEvent(let event):
            return .init(createdAt: event.createdAt, cid: event.cid)
        case .typeHealthCheckEvent(let event):
            return .init(createdAt: event.createdAt, currentUser: event.me)
        case .typeMemberAddedEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, cid: event.cid, user: event.user)
        case .typeMemberRemovedEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, cid: event.cid, user: event.user)
        case .typeMemberUpdatedEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, cid: event.cid, user: event.user)
        case .typeMessageDeletedEvent(let event):
            return .init(createdAt: event.createdAt, channelMessageCount: event.channelMessageCount, cid: event.cid, message: event.message, user: event.user)
        case .typeMessageDeliveredEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, cid: event.cid, user: event.user)
        case .typeMessageNewEvent(let event):
            return .init(
                createdAt: event.createdAt,
                channel: event.channel,
                channelMessageCount: event.channelMessageCount,
                cid: event.cid,
                groupedUnreadChannels: event.groupedUnreadChannels,
                message: event.message,
                unreadCount: .init(channels: event.unreadChannels, messages: event.totalUnreadCount, threads: nil),
                user: event.user
            )
        case .typeMessageReadEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, cid: event.cid, thread: event.thread, user: event.user)
        case .typeMessageUpdatedEvent(let event):
            return .init(createdAt: event.createdAt, channelMessageCount: event.channelMessageCount, cid: event.cid, message: event.message, user: event.user)
        case .typeNotificationAddedToChannelEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel)
        case .typeNotificationChannelDeletedEvent(let event):
            return .init(
                createdAt: event.createdAt,
                channel: event.channel,
                cid: event.cid,
                groupedUnreadChannels: event.groupedUnreadChannels,
                unreadCount: .init(channels: event.unreadChannels, messages: event.totalUnreadCount, threads: nil)
            )
        case .typeNotificationChannelMutesUpdatedEvent(let event):
            return .init(createdAt: event.createdAt, currentUser: event.me)
        case .typeNotificationInviteAcceptedEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, user: event.user)
        case .typeNotificationInviteRejectedEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, user: event.user)
        case .typeNotificationInvitedEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, cid: event.cid, user: event.user)
        case .typeNotificationMarkReadEvent(let event):
            return .init(
                createdAt: event.createdAt,
                channel: event.channel,
                cid: event.cid,
                groupedUnreadChannels: event.groupedUnreadChannels,
                thread: event.thread,
                unreadCount: .init(channels: event.unreadChannels, messages: event.totalUnreadCount, threads: event.unreadThreads),
                user: event.user
            )
        case .typeNotificationMarkUnreadEvent(let event):
            return .init(
                createdAt: event.createdAt,
                channel: event.channel,
                cid: event.cid,
                groupedUnreadChannels: event.groupedUnreadChannels,
                unreadCount: .init(channels: event.unreadChannels, messages: event.totalUnreadCount, threads: event.unreadThreads),
                user: event.user
            )
        case .typeNotificationNewMessageEvent(let event):
            return .init(
                createdAt: event.createdAt,
                channel: event.channel,
                channelMessageCount: event.channelMessageCount,
                groupedUnreadChannels: event.groupedUnreadChannels,
                message: event.message,
                unreadCount: .init(channels: event.unreadChannels, messages: event.totalUnreadCount, threads: nil)
            )
        case .typeNotificationMutesUpdatedEvent(let event):
            return .init(createdAt: event.createdAt, currentUser: event.me)
        case .typeReminderNotificationEvent(let event):
            return .init(createdAt: event.createdAt)
        case .typeNotificationRemovedFromChannelEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, cid: event.cid, user: event.user)
        case .typeNotificationThreadMessageNewEvent(let event):
            return .init(
                createdAt: event.createdAt,
                channel: event.channel,
                channelMessageCount: event.channelMessageCount,
                cid: event.cid,
                message: event.message,
                unreadCount: .init(channels: nil, messages: nil, threads: event.unreadThreads)
            )
        case .typePollClosedEvent(let event):
            return .init(createdAt: event.createdAt, poll: event.poll)
        case .typePollDeletedEvent(let event):
            return .init(createdAt: event.createdAt, poll: event.poll)
        case .typePollUpdatedEvent(let event):
            return .init(createdAt: event.createdAt, poll: event.poll)
        case .typePollVoteCastedEvent(let event):
            return .init(createdAt: event.createdAt, poll: event.poll)
        case .typePollVoteChangedEvent(let event):
            return .init(createdAt: event.createdAt, poll: event.poll)
        case .typePollVoteRemovedEvent(let event):
            return .init(createdAt: event.createdAt, poll: event.poll)
        case .typeReactionDeletedEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, channelMessageCount: event.channelMessageCount, cid: event.cid, message: event.message, user: event.user)
        case .typeReactionNewEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, channelMessageCount: event.channelMessageCount, cid: event.cid, message: event.message, user: event.user)
        case .typeReactionUpdatedEvent(let event):
            return .init(createdAt: event.createdAt, channel: event.channel, channelMessageCount: event.channelMessageCount, cid: event.cid, message: event.message, user: event.user)
        case .typeReminderCreatedEvent(let event):
            return .init(createdAt: event.createdAt)
        case .typeReminderDeletedEvent(let event):
            return .init(createdAt: event.createdAt)
        case .typeReminderUpdatedEvent(let event):
            return .init(createdAt: event.createdAt)
        case .typeThreadUpdatedEvent(let event):
            return .init(createdAt: event.createdAt, thread: event.thread)
        case .typeTypingStartEvent(let event):
            return .init(createdAt: event.createdAt, cid: event.cid, user: event.user)
        case .typeTypingStopEvent(let event):
            return .init(createdAt: event.createdAt, cid: event.cid, user: event.user)
        case .typeUserBannedEvent(let event):
            return .init(createdAt: event.createdAt, cid: event.cid, user: event.user)
        case .typeUserMessagesDeletedEvent(let event):
            return .init(createdAt: event.createdAt, user: event.user)
        case .typeUserPresenceChangedEvent(let event):
            return .init(createdAt: event.createdAt, user: event.user)
        case .typeUserUnbannedEvent(let event):
            return .init(createdAt: event.createdAt, cid: event.cid, user: event.user)
        case .typeUserUpdatedEvent(let event):
            return .init(createdAt: event.createdAt, user: event.user)
        case .typeUserWatchingStartEvent(let event):
            return .init(createdAt: event.createdAt, cid: event.cid, user: event.user)
        case .typeUserWatchingStopEvent(let event):
            return .init(createdAt: event.createdAt, cid: event.cid, user: event.user)
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
