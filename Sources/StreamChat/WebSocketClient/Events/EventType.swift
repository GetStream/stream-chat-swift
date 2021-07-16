//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// Event type.
/// Creates an `Event` from a given response with the appropriate event type.
enum EventType: String, Codable {
    case healthCheck = "health.check"
    
    // MARK: User Events
    
    /// When a user presence changed, e.g. online, offline, away.
    case userPresenceChanged = "user.presence.changed"
    /// When a user was updated.
    case userUpdated = "user.updated"
    /// When a user starts watching a channel.
    case userStartWatching = "user.watching.start"
    /// When a user stops watching a channel.
    case userStopWatching = "user.watching.stop"
    /// Sent when a user starts typing.
    case userStartTyping = "typing.start"
    /// Sent when a user stops typing.
    case userStopTyping = "typing.stop"
    /// When a user was banned.
    case userBanned = "user.banned"
    /// When a user was unbanned.
    case userUnbanned = "user.unbanned"
    
    // MARK: Channel Events
    
    /// When a channel was updated.
    case channelUpdated = "channel.updated"
    /// When a channel was deleted.
    case channelDeleted = "channel.deleted"
    /// When a channel was hidden.
    case channelHidden = "channel.hidden"
    /// When a channel is visible.
    case channelVisible = "channel.visible"
    /// When a channel was truncated.
    case channelTruncated = "channel.truncated"

    // MARK: Message Events
    
    /// When a new message was added on a channel.
    case messageNew = "message.new"
    /// When a message was updated.
    case messageUpdated = "message.updated"
    /// When a message was deleted.
    case messageDeleted = "message.deleted"
    /// When a channel was marked as read.
    case messageRead = "message.read"
    
    /// When a member was added to a channel.
    case memberAdded = "member.added"
    /// When a member was updated.
    case memberUpdated = "member.updated"
    /// When a member was removed from a channel.
    case memberRemoved = "member.removed"
    
    // MARK: Reactions
    
    /// When a message reaction was added.
    case reactionNew = "reaction.new"
    /// When a message reaction updated.
    case reactionUpdated = "reaction.updated"
    /// When a message reaction deleted.
    case reactionDeleted = "reaction.deleted"
    
    /// When a message was added to a channel (when clients that are not currently watching the channel).
    case notificationMessageNew = "notification.message_new"
    /// When the total count of unread messages (across all channels the user is a member) changes
    /// (when clients from the user affected by the change).
    case notificationMarkRead = "notification.mark_read"
    /// When the user mutes someone.
    case notificationMutesUpdated = "notification.mutes_updated"
    /// When someone else from channel has muted someone.
    case notificationChannelMutesUpdated = "notification.channel_mutes_updated"
    
    /// When a user is added to a channel.
    case notificationAddedToChannel = "notification.added_to_channel"
    
    /// When a user is invited to a channel
    case notificationInvited = "notification.invited"
    
    /// When a user accepted a channel invitation
    case notificationInviteAccepted = "notification.invite_accepted"
    
    /// When a user rejected a channel invitation
    case notificationInviteRejected = "notification.invite_rejected"

    /// When a user was removed from a channel.
    case notificationRemovedFromChannel = "notification.removed_from_channel"
        
    func event<ExtraData: ExtraDataTypes>(from response: EventPayload<ExtraData>) throws -> Event {
        switch self {
        case .healthCheck: return try HealthCheckEvent(from: response)
            
        case .userPresenceChanged: return try UserPresenceChangedEvent(from: response)
        case .userUpdated: return try UserUpdatedEvent(from: response)
        case .userStartWatching, .userStopWatching: return try UserWatchingEvent(from: response)
        case .userStartTyping, .userStopTyping: return try TypingEvent(from: response)
        case .userBanned: return try UserBannedEvent(from: response)
        case .userUnbanned: return try UserUnbannedEvent(from: response)

        case .channelUpdated: return try ChannelUpdatedEvent(from: response)
        case .channelDeleted: return try ChannelDeletedEvent(from: response)
        case .channelHidden: return try ChannelHiddenEvent(from: response)
        case .channelTruncated: return try ChannelTruncatedEvent(from: response)
        case .channelVisible: return try ChannelVisibleEvent(from: response)
            
        case .messageNew: return try MessageNewEvent(from: response)
        case .messageUpdated: return try MessageUpdatedEvent(from: response)
        case .messageDeleted: return try MessageDeletedEvent(from: response)
        case .messageRead: return try MessageReadEvent(from: response)
            
        case .memberAdded: return try MemberAddedEvent(from: response)
        case .memberUpdated: return try MemberUpdatedEvent(from: response)
        case .memberRemoved: return try MemberRemovedEvent(from: response)
            
        case .reactionNew: return try ReactionNewEvent(from: response)
        case .reactionUpdated: return try ReactionUpdatedEvent(from: response)
        case .reactionDeleted: return try ReactionDeletedEvent(from: response)
            
        case .notificationMessageNew: return try NotificationMessageNewEvent(from: response)
        
        case .notificationMarkRead:
            return response.channel == nil
                ? try NotificationMarkAllReadEvent(from: response)
                : try NotificationMarkReadEvent(from: response)
            
        case .notificationMutesUpdated: return try NotificationMutesUpdatedEvent(from: response)
        case .notificationAddedToChannel: return try NotificationAddedToChannelEvent(from: response)
        case .notificationRemovedFromChannel: return try NotificationRemovedFromChannelEvent(from: response)
        case .notificationChannelMutesUpdated: return try NotificationChannelMutesUpdatedEvent(from: response)
        case .notificationInvited:
            return try NotificationInvitedEvent(from: response)
        case .notificationInviteAccepted:
            return try NotificationInviteAccepted(from: response)
        case .notificationInviteRejected:
            return try NotificationInviteRejected(from: response)
        }
    }
}
