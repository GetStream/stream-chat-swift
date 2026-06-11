//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An event type.
public struct EventType: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

public extension EventType {
    static let healthCheck: Self = "health.check"
    static let connectionOk: Self = "connection.ok"
    static let connectionError: Self = "connection.error"

    // MARK: User Events

    /// When a user presence changed, e.g. online, offline, away.
    static let userPresenceChanged: Self = "user.presence.changed"
    /// When a user was updated.
    static let userUpdated: Self = "user.updated"
    /// When a user starts watching a channel.
    static let userStartWatching: Self = "user.watching.start"
    /// When a user stops watching a channel.
    static let userStopWatching: Self = "user.watching.stop"
    /// Sent when a user starts typing.
    static let userStartTyping: Self = "typing.start"
    /// Sent when a user stops typing.
    static let userStopTyping: Self = "typing.stop"
    /// When a user was banned.
    static let userBanned: Self = "user.banned"
    /// When a user was unbanned.
    static let userUnbanned: Self = "user.unbanned"
    /// When the messages of a banned user should be deleted.
    static let userMessagesDeleted: Self = "user.messages.deleted"

    // MARK: Channel Events

    /// When a channel was updated.
    static let channelCreated: Self = "channel.created"
    /// When a channel was updated.
    static let channelUpdated: Self = "channel.updated"
    /// When a channel was deleted.
    static let channelDeleted: Self = "channel.deleted"
    /// When a channel was hidden.
    static let channelHidden: Self = "channel.hidden"
    /// When a channel is visible.
    static let channelVisible: Self = "channel.visible"
    /// When a channel was truncated.
    static let channelTruncated: Self = "channel.truncated"

    // MARK: Message Events

    /// When a new message was added on a channel.
    static let messageNew: Self = "message.new"
    /// When a message was updated.
    static let messageUpdated: Self = "message.updated"
    /// When a message was deleted.
    static let messageDeleted: Self = "message.deleted"
    /// When a channel was marked as read.
    static let messageRead: Self = "message.read"
    /// When a message was delivered to a user.
    static let messageDelivered: Self = "message.delivered"

    /// When a member was added to a channel.
    static let memberAdded: Self = "member.added"
    /// When a member was updated.
    static let memberUpdated: Self = "member.updated"
    /// When a member was removed from a channel.
    static let memberRemoved: Self = "member.removed"

    // MARK: Reactions

    /// When a message reaction was added.
    static let reactionNew: Self = "reaction.new"
    /// When a message reaction updated.
    static let reactionUpdated: Self = "reaction.updated"
    /// When a message reaction deleted.
    static let reactionDeleted: Self = "reaction.deleted"

    /// When a message was added to a channel (when clients that are not currently watching the channel).
    static let notificationMessageNew: Self = "notification.message_new"
    /// When the total count of unread messages (across all channels the user is a member) changes
    /// (when clients from the user affected by the change).
    static let notificationMarkRead: Self = "notification.mark_read"

    /// When a message of a channel is marked as unread
    static let notificationMarkUnread: Self = "notification.mark_unread"

    /// When the user mutes someone.
    static let notificationMutesUpdated: Self = "notification.mutes_updated"
    /// When someone else from channel has muted someone.
    static let notificationChannelMutesUpdated: Self = "notification.channel_mutes_updated"

    /// When a user is added to a channel.
    static let notificationAddedToChannel: Self = "notification.added_to_channel"

    /// When a user is invited to a channel
    static let notificationInvited: Self = "notification.invited"

    /// When a user accepted a channel invitation
    static let notificationInviteAccepted: Self = "notification.invite_accepted"

    /// When a user rejected a channel invitation
    static let notificationInviteRejected: Self = "notification.invite_rejected"

    /// When a user was removed from a channel.
    static let notificationRemovedFromChannel: Self = "notification.removed_from_channel"

    /// When a channel was deleted
    static let notificationChannelDeleted: Self = "notification.channel_deleted"
    
    // MARK: - polls

    /// When a poll was created.
    @available(*, deprecated, message: "The server never delivers poll.created; new polls arrive through message.new with the poll attached.")
    static let pollCreated: Self = "poll.created"

    /// When a poll was closed.
    static let pollClosed: Self = "poll.closed"

    /// When a poll was deleted.
    static let pollDeleted: Self = "poll.deleted"

    /// When a poll was updated.
    static let pollUpdated: Self = "poll.updated"

    /// When a vote was casted in a poll.
    static let pollVoteCasted: Self = "poll.vote_casted"

    /// When a vote was changed in a poll.
    static let pollVoteChanged: Self = "poll.vote_changed"

    /// When a vote was removed from a poll.
    static let pollVoteRemoved: Self = "poll.vote_removed"

    // MARK: - threads

    /// When a thread is updated.
    static let threadUpdated: Self = "thread.updated"

    /// When a thread has a new reply.
    static let threadMessageNew: Self = "notification.thread_message_new"
    
    // MARK: - AI
    
    // When an AI typing indicator's state has changed.
    static let aiTypingIndicatorChanged: Self = "ai_indicator.update"
    
    // When an AI typing indicator has been cleared.
    static let aiTypingIndicatorClear: Self = "ai_indicator.clear"
    
    // When an AI typing indicator has been stopped.
    static let aiTypingIndicatorStop: Self = "ai_indicator.stop"

    // MARK: - Drafts

    /// When a draft was updated.
    static let draftUpdated: Self = "draft.updated"

    /// When a draft was deleted.
    static let draftDeleted: Self = "draft.deleted"
    
    // MARK: - Reminders
    
    /// When a reminder was created.
    static let messageReminderCreated: Self = "reminder.created"
    
    /// When a reminder was updated.
    static let messageReminderUpdated: Self = "reminder.updated"
    
    /// When a reminder was deleted.
    static let messageReminderDeleted: Self = "reminder.deleted"
    
    /// When a reminder is due.
    static let messageReminderDue: Self = "notification.reminder_due"
}

extension ClientError {
    final class UnknownChannelEvent: ClientError, @unchecked Sendable {
        init(_ type: EventType) {
            super.init("Event with \(type) cannot be decoded as system event.")
        }
    }

    final class UnknownUserEvent: ClientError, @unchecked Sendable {
        init(_ type: EventType) {
            super.init("Event with \(type) cannot be decoded as system event.")
        }
    }
}
