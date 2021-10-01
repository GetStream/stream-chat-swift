//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// An event type.
public struct EventType: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
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
    
    // MARK: Channel Events
    
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
}

extension EventType {
    func event(from response: EventPayload) throws -> Event {
        switch self {
        case .healthCheck: return try HealthCheckEvent(from: response)
        
        case .userPresenceChanged: return try UserPresenceChangedEventDTO(from: response)
        case .userUpdated: return try UserUpdatedEventDTO(from: response)
        case .userStartWatching, .userStopWatching: return try UserWatchingEventDTO(from: response)
        case .userStartTyping, .userStopTyping: return try TypingEventDTO(from: response)
        case .userBanned: return try UserBannedEventDTO(from: response)
        case .userUnbanned: return try UserUnbannedEventDTO(from: response)
        
        case .channelUpdated: return try ChannelUpdatedEventDTO(from: response)
        case .channelDeleted: return try ChannelDeletedEventDTO(from: response)
        case .channelHidden: return try ChannelHiddenEventDTO(from: response)
        case .channelTruncated: return try ChannelTruncatedEventDTO(from: response)
        case .channelVisible: return try ChannelVisibleEventDTO(from: response)
            
        case .messageNew: return try MessageNewEventDTO(from: response)
        case .messageUpdated: return try MessageUpdatedEventDTO(from: response)
        case .messageDeleted: return try MessageDeletedEventDTO(from: response)
        case .messageRead: return try MessageReadEventDTO(from: response)
        
        case .memberAdded: return try MemberAddedEventDTO(from: response)
        case .memberUpdated: return try MemberUpdatedEventDTO(from: response)
        case .memberRemoved: return try MemberRemovedEventDTO(from: response)
            
        case .reactionNew: return try ReactionNewEventDTO(from: response)
        case .reactionUpdated: return try ReactionUpdatedEventDTO(from: response)
        case .reactionDeleted: return try ReactionDeletedEventDTO(from: response)
        
        case .notificationMessageNew: return try NotificationMessageNewEventDTO(from: response)
        
        case .notificationMarkRead:
            return response.channel == nil
                ? try NotificationMarkAllReadEventDTO(from: response)
                : try NotificationMarkReadEventDTO(from: response)
            
        case .notificationMutesUpdated: return try NotificationMutesUpdatedEventDTO(from: response)
        case .notificationAddedToChannel: return try NotificationAddedToChannelEventDTO(from: response)
        case .notificationRemovedFromChannel: return try NotificationRemovedFromChannelEventDTO(from: response)
        case .notificationChannelMutesUpdated: return try NotificationChannelMutesUpdatedEventDTO(from: response)
        case .notificationInvited:
            return try NotificationInvitedEventDTO(from: response)
        case .notificationInviteAccepted:
            return try NotificationInviteAcceptedEventDTO(from: response)
        case .notificationInviteRejected:
            return try NotificationInviteRejectedEventDTO(from: response)
        default:
            throw ClientError.UnknownEvent(response.eventType)
        }
    }
}

extension ClientError {
    class UnknownEvent: ClientError {
        init(_ type: EventType) {
            super.init("Event with \(type) cannot be decoded as system event.")
        }
    }
}
