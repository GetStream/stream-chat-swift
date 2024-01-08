//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

internal class ChatEventMapping: Decodable {
    let type: String
}

public enum StreamChatWSEvent: Codable, Hashable {
    case typeChannelCreatedEvent(StreamChatChannelCreatedEvent)
    
    case typeChannelDeletedEvent(StreamChatChannelDeletedEvent)
    
    case typeChannelFrozenEvent(StreamChatChannelFrozenEvent)
    
    case typeChannelHiddenEvent(StreamChatChannelHiddenEvent)
    
    case typeChannelKickedEvent(StreamChatChannelKickedEvent)
    
    case typeChannelTruncatedEvent(StreamChatChannelTruncatedEvent)
    
    case typeChannelUnFrozenEvent(StreamChatChannelUnFrozenEvent)
    
    case typeChannelUpdatedEvent(StreamChatChannelUpdatedEvent)
    
    case typeChannelVisibleEvent(StreamChatChannelVisibleEvent)
    
    case typeAnyEvent(StreamChatAnyEvent)
    
    case typeHealthCheckEvent(StreamChatHealthCheckEvent)
    
    case typeMemberAddedEvent(StreamChatMemberAddedEvent)
    
    case typeMemberRemovedEvent(StreamChatMemberRemovedEvent)
    
    case typeMemberUpdatedEvent(StreamChatMemberUpdatedEvent)
    
    case typeMessageDeletedEvent(StreamChatMessageDeletedEvent)
    
    case typeMessageNewEvent(StreamChatMessageNewEvent)
    
    case typeMessageReadEvent(StreamChatMessageReadEvent)
    
    case typeMessageUpdatedEvent(StreamChatMessageUpdatedEvent)
    
    case typeNotificationAddedToChannelEvent(StreamChatNotificationAddedToChannelEvent)
    
    case typeNotificationChannelDeletedEvent(StreamChatNotificationChannelDeletedEvent)
    
    case typeNotificationChannelMutesUpdatedEvent(StreamChatNotificationChannelMutesUpdatedEvent)
    
    case typeNotificationChannelTruncatedEvent(StreamChatNotificationChannelTruncatedEvent)
    
    case typeNotificationInviteAcceptedEvent(StreamChatNotificationInviteAcceptedEvent)
    
    case typeNotificationInviteRejectedEvent(StreamChatNotificationInviteRejectedEvent)
    
    case typeNotificationInvitedEvent(StreamChatNotificationInvitedEvent)
    
    case typeNotificationMarkReadEvent(StreamChatNotificationMarkReadEvent)
    
    case typeNotificationMarkUnreadEvent(StreamChatNotificationMarkUnreadEvent)
    
    case typeNotificationNewMessageEvent(StreamChatNotificationNewMessageEvent)
    
    case typeNotificationMutesUpdatedEvent(StreamChatNotificationMutesUpdatedEvent)
    
    case typeNotificationRemovedFromChannelEvent(StreamChatNotificationRemovedFromChannelEvent)
    
    case typeReactionDeletedEvent(StreamChatReactionDeletedEvent)
    
    case typeReactionNewEvent(StreamChatReactionNewEvent)
    
    case typeReactionUpdatedEvent(StreamChatReactionUpdatedEvent)
    
    case typeTypingStartEvent(StreamChatTypingStartEvent)
    
    case typeTypingStopEvent(StreamChatTypingStopEvent)
    
    case typeUserBannedEvent(StreamChatUserBannedEvent)
    
    case typeUserDeactivatedEvent(StreamChatUserDeactivatedEvent)
    
    case typeUserDeletedEvent(StreamChatUserDeletedEvent)
    
    case typeUserMutedEvent(StreamChatUserMutedEvent)
    
    case typeUserPresenceChangedEvent(StreamChatUserPresenceChangedEvent)
    
    case typeUserReactivatedEvent(StreamChatUserReactivatedEvent)
    
    case typeUserUnbannedEvent(StreamChatUserUnbannedEvent)
    
    case typeUserUnreadReminderEvent(StreamChatUserUnreadReminderEvent)
    
    case typeUserUpdatedEvent(StreamChatUserUpdatedEvent)
    
    case typeUserWatchingStartEvent(StreamChatUserWatchingStartEvent)
    
    case typeUserWatchingStopEvent(StreamChatUserWatchingStopEvent)
    
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
        case let .typeReactionDeletedEvent(value):
            return value.type
        case let .typeReactionNewEvent(value):
            return value.type
        case let .typeReactionUpdatedEvent(value):
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
        case let .typeUserUnreadReminderEvent(value):
            return value.type
        case let .typeUserUpdatedEvent(value):
            return value.type
        case let .typeUserWatchingStartEvent(value):
            return value.type
        case let .typeUserWatchingStopEvent(value):
            return value.type
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
        case let .typeReactionDeletedEvent(value):
            try container.encode(value)
        case let .typeReactionNewEvent(value):
            try container.encode(value)
        case let .typeReactionUpdatedEvent(value):
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
        case let .typeUserUnreadReminderEvent(value):
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
            let value = try container.decode(StreamChatChannelCreatedEvent.self)
            self = .typeChannelCreatedEvent(value)
        } else if dto.type == "channel.deleted" {
            let value = try container.decode(StreamChatChannelDeletedEvent.self)
            self = .typeChannelDeletedEvent(value)
        } else if dto.type == "channel.frozen" {
            let value = try container.decode(StreamChatChannelFrozenEvent.self)
            self = .typeChannelFrozenEvent(value)
        } else if dto.type == "channel.hidden" {
            let value = try container.decode(StreamChatChannelHiddenEvent.self)
            self = .typeChannelHiddenEvent(value)
        } else if dto.type == "channel.kicked" {
            let value = try container.decode(StreamChatChannelKickedEvent.self)
            self = .typeChannelKickedEvent(value)
        } else if dto.type == "channel.truncated" {
            let value = try container.decode(StreamChatChannelTruncatedEvent.self)
            self = .typeChannelTruncatedEvent(value)
        } else if dto.type == "channel.unfrozen" {
            let value = try container.decode(StreamChatChannelUnFrozenEvent.self)
            self = .typeChannelUnFrozenEvent(value)
        } else if dto.type == "channel.updated" {
            let value = try container.decode(StreamChatChannelUpdatedEvent.self)
            self = .typeChannelUpdatedEvent(value)
        } else if dto.type == "channel.visible" {
            let value = try container.decode(StreamChatChannelVisibleEvent.self)
            self = .typeChannelVisibleEvent(value)
        } else if dto.type == "custom" {
            let value = try container.decode(StreamChatAnyEvent.self)
            self = .typeAnyEvent(value)
        } else if dto.type == "health.check" {
            let value = try container.decode(StreamChatHealthCheckEvent.self)
            self = .typeHealthCheckEvent(value)
        } else if dto.type == "member.added" {
            let value = try container.decode(StreamChatMemberAddedEvent.self)
            self = .typeMemberAddedEvent(value)
        } else if dto.type == "member.removed" {
            let value = try container.decode(StreamChatMemberRemovedEvent.self)
            self = .typeMemberRemovedEvent(value)
        } else if dto.type == "member.updated" {
            let value = try container.decode(StreamChatMemberUpdatedEvent.self)
            self = .typeMemberUpdatedEvent(value)
        } else if dto.type == "message.deleted" {
            let value = try container.decode(StreamChatMessageDeletedEvent.self)
            self = .typeMessageDeletedEvent(value)
        } else if dto.type == "message.new" {
            let value = try container.decode(StreamChatMessageNewEvent.self)
            self = .typeMessageNewEvent(value)
        } else if dto.type == "message.read" {
            let value = try container.decode(StreamChatMessageReadEvent.self)
            self = .typeMessageReadEvent(value)
        } else if dto.type == "message.updated" {
            let value = try container.decode(StreamChatMessageUpdatedEvent.self)
            self = .typeMessageUpdatedEvent(value)
        } else if dto.type == "notification.added_to_channel" {
            let value = try container.decode(StreamChatNotificationAddedToChannelEvent.self)
            self = .typeNotificationAddedToChannelEvent(value)
        } else if dto.type == "notification.channel_deleted" {
            let value = try container.decode(StreamChatNotificationChannelDeletedEvent.self)
            self = .typeNotificationChannelDeletedEvent(value)
        } else if dto.type == "notification.channel_mutes_updated" {
            let value = try container.decode(StreamChatNotificationChannelMutesUpdatedEvent.self)
            self = .typeNotificationChannelMutesUpdatedEvent(value)
        } else if dto.type == "notification.channel_truncated" {
            let value = try container.decode(StreamChatNotificationChannelTruncatedEvent.self)
            self = .typeNotificationChannelTruncatedEvent(value)
        } else if dto.type == "notification.invite_accepted" {
            let value = try container.decode(StreamChatNotificationInviteAcceptedEvent.self)
            self = .typeNotificationInviteAcceptedEvent(value)
        } else if dto.type == "notification.invite_rejected" {
            let value = try container.decode(StreamChatNotificationInviteRejectedEvent.self)
            self = .typeNotificationInviteRejectedEvent(value)
        } else if dto.type == "notification.invited" {
            let value = try container.decode(StreamChatNotificationInvitedEvent.self)
            self = .typeNotificationInvitedEvent(value)
        } else if dto.type == "notification.mark_read" {
            let value = try container.decode(StreamChatNotificationMarkReadEvent.self)
            self = .typeNotificationMarkReadEvent(value)
        } else if dto.type == "notification.mark_unread" {
            let value = try container.decode(StreamChatNotificationMarkUnreadEvent.self)
            self = .typeNotificationMarkUnreadEvent(value)
        } else if dto.type == "notification.message_new" {
            let value = try container.decode(StreamChatNotificationNewMessageEvent.self)
            self = .typeNotificationNewMessageEvent(value)
        } else if dto.type == "notification.mutes_updated" {
            let value = try container.decode(StreamChatNotificationMutesUpdatedEvent.self)
            self = .typeNotificationMutesUpdatedEvent(value)
        } else if dto.type == "notification.removed_from_channel" {
            let value = try container.decode(StreamChatNotificationRemovedFromChannelEvent.self)
            self = .typeNotificationRemovedFromChannelEvent(value)
        } else if dto.type == "reaction.deleted" {
            let value = try container.decode(StreamChatReactionDeletedEvent.self)
            self = .typeReactionDeletedEvent(value)
        } else if dto.type == "reaction.new" {
            let value = try container.decode(StreamChatReactionNewEvent.self)
            self = .typeReactionNewEvent(value)
        } else if dto.type == "reaction.updated" {
            let value = try container.decode(StreamChatReactionUpdatedEvent.self)
            self = .typeReactionUpdatedEvent(value)
        } else if dto.type == "typing.start" {
            let value = try container.decode(StreamChatTypingStartEvent.self)
            self = .typeTypingStartEvent(value)
        } else if dto.type == "typing.stop" {
            let value = try container.decode(StreamChatTypingStopEvent.self)
            self = .typeTypingStopEvent(value)
        } else if dto.type == "user.banned" {
            let value = try container.decode(StreamChatUserBannedEvent.self)
            self = .typeUserBannedEvent(value)
        } else if dto.type == "user.deactivated" {
            let value = try container.decode(StreamChatUserDeactivatedEvent.self)
            self = .typeUserDeactivatedEvent(value)
        } else if dto.type == "user.deleted" {
            let value = try container.decode(StreamChatUserDeletedEvent.self)
            self = .typeUserDeletedEvent(value)
        } else if dto.type == "user.muted" {
            let value = try container.decode(StreamChatUserMutedEvent.self)
            self = .typeUserMutedEvent(value)
        } else if dto.type == "user.presence.changed" {
            let value = try container.decode(StreamChatUserPresenceChangedEvent.self)
            self = .typeUserPresenceChangedEvent(value)
        } else if dto.type == "user.reactivated" {
            let value = try container.decode(StreamChatUserReactivatedEvent.self)
            self = .typeUserReactivatedEvent(value)
        } else if dto.type == "user.unbanned" {
            let value = try container.decode(StreamChatUserUnbannedEvent.self)
            self = .typeUserUnbannedEvent(value)
        } else if dto.type == "user.unread_message_reminder" {
            let value = try container.decode(StreamChatUserUnreadReminderEvent.self)
            self = .typeUserUnreadReminderEvent(value)
        } else if dto.type == "user.updated" {
            let value = try container.decode(StreamChatUserUpdatedEvent.self)
            self = .typeUserUpdatedEvent(value)
        } else if dto.type == "user.watching.start" {
            let value = try container.decode(StreamChatUserWatchingStartEvent.self)
            self = .typeUserWatchingStartEvent(value)
        } else if dto.type == "user.watching.stop" {
            let value = try container.decode(StreamChatUserWatchingStopEvent.self)
            self = .typeUserWatchingStopEvent(value)
        } else {
            throw DecodingError.typeMismatch(
                Self.Type.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Unable to decode instance of chat event")
            )
        }
    }
}
