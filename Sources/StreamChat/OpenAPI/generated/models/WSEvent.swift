//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

internal class ChatEventMapping: Decodable {
    let type: String
}

public enum WSEvent: Codable, Hashable {
    case typeChannelCreatedEvent(ChannelCreatedEvent)
    case typeChannelDeletedEvent(ChannelDeletedEvent)
    case typeChannelFrozenEvent(ChannelFrozenEvent)
    case typeChannelHiddenEvent(ChannelHiddenEvent)
    case typeChannelKickedEvent(ChannelKickedEvent)
    case typeChannelTruncatedEvent(ChannelTruncatedEvent)
    case typeChannelUnFrozenEvent(ChannelUnFrozenEvent)
    case typeChannelUpdatedEvent(ChannelUpdatedEvent)
    case typeChannelVisibleEvent(ChannelVisibleEvent)
    case typeAnyEvent(AnyEvent)
    case typeHealthCheckEvent(HealthCheckEvent)
    case typeMemberAddedEvent(MemberAddedEvent)
    case typeMemberRemovedEvent(MemberRemovedEvent)
    case typeMemberUpdatedEvent(MemberUpdatedEvent)
    case typeMessageDeletedEvent(MessageDeletedEvent)
    case typeMessageNewEvent(MessageNewEvent)
    case typeMessageReadEvent(MessageReadEvent)
    case typeMessageUndeletedEvent(MessageUndeletedEvent)
    case typeMessageUpdatedEvent(MessageUpdatedEvent)
    case typeNotificationAddedToChannelEvent(NotificationAddedToChannelEvent)
    case typeNotificationChannelDeletedEvent(NotificationChannelDeletedEvent)
    case typeNotificationChannelMutesUpdatedEvent(NotificationChannelMutesUpdatedEvent)
    case typeNotificationChannelTruncatedEvent(NotificationChannelTruncatedEvent)
    case typeNotificationInviteAcceptedEvent(NotificationInviteAcceptedEvent)
    case typeNotificationInviteRejectedEvent(NotificationInviteRejectedEvent)
    case typeNotificationInvitedEvent(NotificationInvitedEvent)
    case typeNotificationMarkReadEvent(NotificationMarkReadEvent)
    case typeNotificationMarkUnreadEvent(NotificationMarkUnreadEvent)
    case typeNotificationNewMessageEvent(NotificationNewMessageEvent)
    case typeNotificationMutesUpdatedEvent(NotificationMutesUpdatedEvent)
    case typeNotificationRemovedFromChannelEvent(NotificationRemovedFromChannelEvent)
    case typeReactionDeletedEvent(ReactionDeletedEvent)
    case typeReactionNewEvent(ReactionNewEvent)
    case typeReactionUpdatedEvent(ReactionUpdatedEvent)
    case typeThreadUpdatedEvent(ThreadUpdatedEvent)
    case typeTypingStartEvent(TypingStartEvent)
    case typeTypingStopEvent(TypingStopEvent)
    case typeUserBannedEvent(UserBannedEvent)
    case typeUserDeactivatedEvent(UserDeactivatedEvent)
    case typeUserDeletedEvent(UserDeletedEvent)
    case typeUserMutedEvent(UserMutedEvent)
    case typeUserPresenceChangedEvent(UserPresenceChangedEvent)
    case typeUserReactivatedEvent(UserReactivatedEvent)
    case typeUserUnbannedEvent(UserUnbannedEvent)
    case typeUserUpdatedEvent(UserUpdatedEvent)
    case typeUserWatchingStartEvent(UserWatchingStartEvent)
    case typeUserWatchingStopEvent(UserWatchingStopEvent)

    public var type: String {
        switch self {
        case let .typeChannelCreatedEvent(value):
            return value.type
        case let .typeChannelDeletedEvent(value):
            return value.type
        case let .typeChannelFrozenEvent(value):
            return value.type
        case let .typeChannelHiddenEvent(value):
            return value.type
        case let .typeChannelKickedEvent(value):
            return value.type
        case let .typeChannelTruncatedEvent(value):
            return value.type
        case let .typeChannelUnFrozenEvent(value):
            return value.type
        case let .typeChannelUpdatedEvent(value):
            return value.type
        case let .typeChannelVisibleEvent(value):
            return value.type
        case let .typeAnyEvent(value):
            return value.type
        case let .typeHealthCheckEvent(value):
            return value.type
        case let .typeMemberAddedEvent(value):
            return value.type
        case let .typeMemberRemovedEvent(value):
            return value.type
        case let .typeMemberUpdatedEvent(value):
            return value.type
        case let .typeMessageDeletedEvent(value):
            return value.type
        case let .typeMessageNewEvent(value):
            return value.type
        case let .typeMessageReadEvent(value):
            return value.type
        case let .typeMessageUndeletedEvent(value):
            return value.type
        case let .typeMessageUpdatedEvent(value):
            return value.type
        case let .typeNotificationAddedToChannelEvent(value):
            return value.type
        case let .typeNotificationChannelDeletedEvent(value):
            return value.type
        case let .typeNotificationChannelMutesUpdatedEvent(value):
            return value.type
        case let .typeNotificationChannelTruncatedEvent(value):
            return value.type
        case let .typeNotificationInviteAcceptedEvent(value):
            return value.type
        case let .typeNotificationInviteRejectedEvent(value):
            return value.type
        case let .typeNotificationInvitedEvent(value):
            return value.type
        case let .typeNotificationMarkReadEvent(value):
            return value.type
        case let .typeNotificationMarkUnreadEvent(value):
            return value.type
        case let .typeNotificationNewMessageEvent(value):
            return value.type
        case let .typeNotificationMutesUpdatedEvent(value):
            return value.type
        case let .typeNotificationRemovedFromChannelEvent(value):
            return value.type
        case let .typeMessageNewEvent(value):
            return value.type
        case let .typeReactionDeletedEvent(value):
            return value.type
        case let .typeReactionNewEvent(value):
            return value.type
        case let .typeReactionUpdatedEvent(value):
            return value.type
        case let .typeThreadUpdatedEvent(value):
            return value.type
        case let .typeTypingStartEvent(value):
            return value.type
        case let .typeTypingStopEvent(value):
            return value.type
        case let .typeUserBannedEvent(value):
            return value.type
        case let .typeUserDeactivatedEvent(value):
            return value.type
        case let .typeUserDeletedEvent(value):
            return value.type
        case let .typeUserMutedEvent(value):
            return value.type
        case let .typeUserPresenceChangedEvent(value):
            return value.type
        case let .typeUserReactivatedEvent(value):
            return value.type
        case let .typeUserUnbannedEvent(value):
            return value.type
        case let .typeUserUpdatedEvent(value):
            return value.type
        case let .typeUserWatchingStartEvent(value):
            return value.type
        case let .typeUserWatchingStopEvent(value):
            return value.type
        }
    }

    public var rawValue: Event {
        switch self {
        case let .typeChannelCreatedEvent(value):
            return value
        case let .typeChannelDeletedEvent(value):
            return value
        case let .typeChannelFrozenEvent(value):
            return value
        case let .typeChannelHiddenEvent(value):
            return value
        case let .typeChannelKickedEvent(value):
            return value
        case let .typeChannelTruncatedEvent(value):
            return value
        case let .typeChannelUnFrozenEvent(value):
            return value
        case let .typeChannelUpdatedEvent(value):
            return value
        case let .typeChannelVisibleEvent(value):
            return value
        case let .typeAnyEvent(value):
            return value
        case let .typeHealthCheckEvent(value):
            return value
        case let .typeMemberAddedEvent(value):
            return value
        case let .typeMemberRemovedEvent(value):
            return value
        case let .typeMemberUpdatedEvent(value):
            return value
        case let .typeMessageDeletedEvent(value):
            return value
        case let .typeMessageNewEvent(value):
            return value
        case let .typeMessageReadEvent(value):
            return value
        case let .typeMessageUndeletedEvent(value):
            return value
        case let .typeMessageUpdatedEvent(value):
            return value
        case let .typeNotificationAddedToChannelEvent(value):
            return value
        case let .typeNotificationChannelDeletedEvent(value):
            return value
        case let .typeNotificationChannelMutesUpdatedEvent(value):
            return value
        case let .typeNotificationChannelTruncatedEvent(value):
            return value
        case let .typeNotificationInviteAcceptedEvent(value):
            return value
        case let .typeNotificationInviteRejectedEvent(value):
            return value
        case let .typeNotificationInvitedEvent(value):
            return value
        case let .typeNotificationMarkReadEvent(value):
            return value
        case let .typeNotificationMarkUnreadEvent(value):
            return value
        case let .typeNotificationNewMessageEvent(value):
            return value
        case let .typeNotificationMutesUpdatedEvent(value):
            return value
        case let .typeNotificationRemovedFromChannelEvent(value):
            return value
        case let .typeMessageNewEvent(value):
            return value
        case let .typeReactionDeletedEvent(value):
            return value
        case let .typeReactionNewEvent(value):
            return value
        case let .typeReactionUpdatedEvent(value):
            return value
        case let .typeThreadUpdatedEvent(value):
            return value
        case let .typeTypingStartEvent(value):
            return value
        case let .typeTypingStopEvent(value):
            return value
        case let .typeUserBannedEvent(value):
            return value
        case let .typeUserDeactivatedEvent(value):
            return value
        case let .typeUserDeletedEvent(value):
            return value
        case let .typeUserMutedEvent(value):
            return value
        case let .typeUserPresenceChangedEvent(value):
            return value
        case let .typeUserReactivatedEvent(value):
            return value
        case let .typeUserUnbannedEvent(value):
            return value
        case let .typeUserUpdatedEvent(value):
            return value
        case let .typeUserWatchingStartEvent(value):
            return value
        case let .typeUserWatchingStopEvent(value):
            return value
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .typeChannelCreatedEvent(value):
            try container.encode(value)
        case let .typeChannelDeletedEvent(value):
            try container.encode(value)
        case let .typeChannelFrozenEvent(value):
            try container.encode(value)
        case let .typeChannelHiddenEvent(value):
            try container.encode(value)
        case let .typeChannelKickedEvent(value):
            try container.encode(value)
        case let .typeChannelTruncatedEvent(value):
            try container.encode(value)
        case let .typeChannelUnFrozenEvent(value):
            try container.encode(value)
        case let .typeChannelUpdatedEvent(value):
            try container.encode(value)
        case let .typeChannelVisibleEvent(value):
            try container.encode(value)
        case let .typeAnyEvent(value):
            try container.encode(value)
        case let .typeHealthCheckEvent(value):
            try container.encode(value)
        case let .typeMemberAddedEvent(value):
            try container.encode(value)
        case let .typeMemberRemovedEvent(value):
            try container.encode(value)
        case let .typeMemberUpdatedEvent(value):
            try container.encode(value)
        case let .typeMessageDeletedEvent(value):
            try container.encode(value)
        case let .typeMessageNewEvent(value):
            try container.encode(value)
        case let .typeMessageReadEvent(value):
            try container.encode(value)
        case let .typeMessageUndeletedEvent(value):
            try container.encode(value)
        case let .typeMessageUpdatedEvent(value):
            try container.encode(value)
        case let .typeNotificationAddedToChannelEvent(value):
            try container.encode(value)
        case let .typeNotificationChannelDeletedEvent(value):
            try container.encode(value)
        case let .typeNotificationChannelMutesUpdatedEvent(value):
            try container.encode(value)
        case let .typeNotificationChannelTruncatedEvent(value):
            try container.encode(value)
        case let .typeNotificationInviteAcceptedEvent(value):
            try container.encode(value)
        case let .typeNotificationInviteRejectedEvent(value):
            try container.encode(value)
        case let .typeNotificationInvitedEvent(value):
            try container.encode(value)
        case let .typeNotificationMarkReadEvent(value):
            try container.encode(value)
        case let .typeNotificationMarkUnreadEvent(value):
            try container.encode(value)
        case let .typeNotificationNewMessageEvent(value):
            try container.encode(value)
        case let .typeNotificationMutesUpdatedEvent(value):
            try container.encode(value)
        case let .typeNotificationRemovedFromChannelEvent(value):
            try container.encode(value)
        case let .typeMessageNewEvent(value):
            try container.encode(value)
        case let .typeReactionDeletedEvent(value):
            try container.encode(value)
        case let .typeReactionNewEvent(value):
            try container.encode(value)
        case let .typeReactionUpdatedEvent(value):
            try container.encode(value)
        case let .typeThreadUpdatedEvent(value):
            try container.encode(value)
        case let .typeTypingStartEvent(value):
            try container.encode(value)
        case let .typeTypingStopEvent(value):
            try container.encode(value)
        case let .typeUserBannedEvent(value):
            try container.encode(value)
        case let .typeUserDeactivatedEvent(value):
            try container.encode(value)
        case let .typeUserDeletedEvent(value):
            try container.encode(value)
        case let .typeUserMutedEvent(value):
            try container.encode(value)
        case let .typeUserPresenceChangedEvent(value):
            try container.encode(value)
        case let .typeUserReactivatedEvent(value):
            try container.encode(value)
        case let .typeUserUnbannedEvent(value):
            try container.encode(value)
        case let .typeUserUpdatedEvent(value):
            try container.encode(value)
        case let .typeUserWatchingStartEvent(value):
            try container.encode(value)
        case let .typeUserWatchingStopEvent(value):
            try container.encode(value)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dto = try container.decode(ChatEventMapping.self)
        if dto.type == "channel.created" {
            let value = try container.decode(ChannelCreatedEvent.self)
            self = .typeChannelCreatedEvent(value)
        } else if dto.type == "channel.deleted" {
            let value = try container.decode(ChannelDeletedEvent.self)
            self = .typeChannelDeletedEvent(value)
        } else if dto.type == "channel.frozen" {
            let value = try container.decode(ChannelFrozenEvent.self)
            self = .typeChannelFrozenEvent(value)
        } else if dto.type == "channel.hidden" {
            let value = try container.decode(ChannelHiddenEvent.self)
            self = .typeChannelHiddenEvent(value)
        } else if dto.type == "channel.kicked" {
            let value = try container.decode(ChannelKickedEvent.self)
            self = .typeChannelKickedEvent(value)
        } else if dto.type == "channel.truncated" {
            let value = try container.decode(ChannelTruncatedEvent.self)
            self = .typeChannelTruncatedEvent(value)
        } else if dto.type == "channel.unfrozen" {
            let value = try container.decode(ChannelUnFrozenEvent.self)
            self = .typeChannelUnFrozenEvent(value)
        } else if dto.type == "channel.updated" {
            let value = try container.decode(ChannelUpdatedEvent.self)
            self = .typeChannelUpdatedEvent(value)
        } else if dto.type == "channel.visible" {
            let value = try container.decode(ChannelVisibleEvent.self)
            self = .typeChannelVisibleEvent(value)
        } else if dto.type == "custom" {
            let value = try container.decode(AnyEvent.self)
            self = .typeAnyEvent(value)
        } else if dto.type == "health.check" || dto.type == "connection.ok" {
            let value = try container.decode(HealthCheckEvent.self)
            self = .typeHealthCheckEvent(value)
        } else if dto.type == "member.added" {
            let value = try container.decode(MemberAddedEvent.self)
            self = .typeMemberAddedEvent(value)
        } else if dto.type == "member.removed" {
            let value = try container.decode(MemberRemovedEvent.self)
            self = .typeMemberRemovedEvent(value)
        } else if dto.type == "member.updated" {
            let value = try container.decode(MemberUpdatedEvent.self)
            self = .typeMemberUpdatedEvent(value)
        } else if dto.type == "message.deleted" {
            let value = try container.decode(MessageDeletedEvent.self)
            self = .typeMessageDeletedEvent(value)
        } else if dto.type == "message.new" {
            let value = try container.decode(MessageNewEvent.self)
            self = .typeMessageNewEvent(value)
        } else if dto.type == "message.read" {
            let value = try container.decode(MessageReadEvent.self)
            self = .typeMessageReadEvent(value)
        } else if dto.type == "message.undeleted" {
            let value = try container.decode(MessageUndeletedEvent.self)
            self = .typeMessageUndeletedEvent(value)
        } else if dto.type == "message.updated" {
            let value = try container.decode(MessageUpdatedEvent.self)
            self = .typeMessageUpdatedEvent(value)
        } else if dto.type == "notification.added_to_channel" {
            let value = try container.decode(NotificationAddedToChannelEvent.self)
            self = .typeNotificationAddedToChannelEvent(value)
        } else if dto.type == "notification.channel_deleted" {
            let value = try container.decode(NotificationChannelDeletedEvent.self)
            self = .typeNotificationChannelDeletedEvent(value)
        } else if dto.type == "notification.channel_mutes_updated" {
            let value = try container.decode(NotificationChannelMutesUpdatedEvent.self)
            self = .typeNotificationChannelMutesUpdatedEvent(value)
        } else if dto.type == "notification.channel_truncated" {
            let value = try container.decode(NotificationChannelTruncatedEvent.self)
            self = .typeNotificationChannelTruncatedEvent(value)
        } else if dto.type == "notification.invite_accepted" {
            let value = try container.decode(NotificationInviteAcceptedEvent.self)
            self = .typeNotificationInviteAcceptedEvent(value)
        } else if dto.type == "notification.invite_rejected" {
            let value = try container.decode(NotificationInviteRejectedEvent.self)
            self = .typeNotificationInviteRejectedEvent(value)
        } else if dto.type == "notification.invited" {
            let value = try container.decode(NotificationInvitedEvent.self)
            self = .typeNotificationInvitedEvent(value)
        } else if dto.type == "notification.mark_read" {
            let value = try container.decode(NotificationMarkReadEvent.self)
            self = .typeNotificationMarkReadEvent(value)
        } else if dto.type == "notification.mark_unread" {
            let value = try container.decode(NotificationMarkUnreadEvent.self)
            self = .typeNotificationMarkUnreadEvent(value)
        } else if dto.type == "notification.message_new" {
            let value = try container.decode(NotificationNewMessageEvent.self)
            self = .typeNotificationNewMessageEvent(value)
        } else if dto.type == "notification.mutes_updated" {
            let value = try container.decode(NotificationMutesUpdatedEvent.self)
            self = .typeNotificationMutesUpdatedEvent(value)
        } else if dto.type == "notification.removed_from_channel" {
            let value = try container.decode(NotificationRemovedFromChannelEvent.self)
            self = .typeNotificationRemovedFromChannelEvent(value)
        } else if dto.type == "notification.thread_message_new" {
            let value = try container.decode(MessageNewEvent.self)
            self = .typeMessageNewEvent(value)
        } else if dto.type == "reaction.deleted" {
            let value = try container.decode(ReactionDeletedEvent.self)
            self = .typeReactionDeletedEvent(value)
        } else if dto.type == "reaction.new" {
            let value = try container.decode(ReactionNewEvent.self)
            self = .typeReactionNewEvent(value)
        } else if dto.type == "reaction.updated" {
            let value = try container.decode(ReactionUpdatedEvent.self)
            self = .typeReactionUpdatedEvent(value)
        } else if dto.type == "thread.updated" {
            let value = try container.decode(ThreadUpdatedEvent.self)
            self = .typeThreadUpdatedEvent(value)
        } else if dto.type == "typing.start" {
            let value = try container.decode(TypingStartEvent.self)
            self = .typeTypingStartEvent(value)
        } else if dto.type == "typing.stop" {
            let value = try container.decode(TypingStopEvent.self)
            self = .typeTypingStopEvent(value)
        } else if dto.type == "user.banned" {
            let value = try container.decode(UserBannedEvent.self)
            self = .typeUserBannedEvent(value)
        } else if dto.type == "user.deactivated" {
            let value = try container.decode(UserDeactivatedEvent.self)
            self = .typeUserDeactivatedEvent(value)
        } else if dto.type == "user.deleted" {
            let value = try container.decode(UserDeletedEvent.self)
            self = .typeUserDeletedEvent(value)
        } else if dto.type == "user.muted" {
            let value = try container.decode(UserMutedEvent.self)
            self = .typeUserMutedEvent(value)
        } else if dto.type == "user.presence.changed" {
            let value = try container.decode(UserPresenceChangedEvent.self)
            self = .typeUserPresenceChangedEvent(value)
        } else if dto.type == "user.reactivated" {
            let value = try container.decode(UserReactivatedEvent.self)
            self = .typeUserReactivatedEvent(value)
        } else if dto.type == "user.unbanned" {
            let value = try container.decode(UserUnbannedEvent.self)
            self = .typeUserUnbannedEvent(value)
        } else if dto.type == "user.updated" {
            let value = try container.decode(UserUpdatedEvent.self)
            self = .typeUserUpdatedEvent(value)
        } else if dto.type == "user.watching.start" {
            let value = try container.decode(UserWatchingStartEvent.self)
            self = .typeUserWatchingStartEvent(value)
        } else if dto.type == "user.watching.stop" {
            let value = try container.decode(UserWatchingStopEvent.self)
            self = .typeUserWatchingStopEvent(value)
        } else {
            throw ClientError.UnknownChannelEvent(EventType(rawValue: dto.type))
        }
    }
}
