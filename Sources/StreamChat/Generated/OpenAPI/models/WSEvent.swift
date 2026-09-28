//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

private class WSEventMapping: Decodable {
    let type: String
}

enum WSEvent: Decodable {
    case typeAIIndicatorClearEvent(AIIndicatorClearEventDTO)
    case typeAIIndicatorStopEvent(AIIndicatorStopEventDTO)
    case typeAIIndicatorUpdateEvent(AIIndicatorUpdateEventDTO)
    case typeChannelDeletedEvent(ChannelDeletedEventDTO)
    case typeChannelHiddenEvent(ChannelHiddenEventDTO)
    case typeChannelTruncatedEvent(ChannelTruncatedEventDTO)
    case typeChannelUpdatedEvent(ChannelUpdatedEventDTO)
    case typeChannelVisibleEvent(ChannelVisibleEventDTO)
    case typeDraftDeletedEvent(DraftDeletedEventDTO)
    case typeDraftUpdatedEvent(DraftUpdatedEventDTO)
    case typeHealthCheckEvent(HealthCheckEventDTO)
    case typeMemberAddedEvent(MemberAddedEventDTO)
    case typeMemberRemovedEvent(MemberRemovedEventDTO)
    case typeMemberUpdatedEvent(MemberUpdatedEventDTO)
    case typeMessageDeletedEvent(MessageDeletedEventDTO)
    case typeMessageDeliveredEvent(MessageDeliveredEventDTO)
    case typeMessageNewEvent(MessageNewEventDTO)
    case typeMessageReadEvent(MessageReadEventDTO)
    case typeMessageUpdatedEvent(MessageUpdatedEventDTO)
    case typeNotificationAddedToChannelEvent(NotificationAddedToChannelEventDTO)
    case typeNotificationChannelDeletedEvent(NotificationChannelDeletedEventDTO)
    case typeNotificationChannelMutesUpdatedEvent(NotificationChannelMutesUpdatedEventDTO)
    case typeNotificationInviteAcceptedEvent(NotificationInviteAcceptedEventDTO)
    case typeNotificationInviteRejectedEvent(NotificationInviteRejectedEventDTO)
    case typeNotificationInvitedEvent(NotificationInvitedEventDTO)
    case typeNotificationMarkReadEvent(NotificationMarkReadEventDTO)
    case typeNotificationMarkUnreadEvent(NotificationMarkUnreadEventDTO)
    case typeNotificationNewMessageEvent(NotificationNewMessageEventDTO)
    case typeNotificationMutesUpdatedEvent(NotificationMutesUpdatedEventDTO)
    case typeReminderNotificationEvent(ReminderNotificationEventDTO)
    case typeNotificationRemovedFromChannelEvent(NotificationRemovedFromChannelEventDTO)
    case typeNotificationThreadMessageNewEvent(NotificationThreadMessageNewEventDTO)
    case typePollClosedEvent(PollClosedEventDTO)
    case typePollDeletedEvent(PollDeletedEventDTO)
    case typePollUpdatedEvent(PollUpdatedEventDTO)
    case typePollVoteCastedEvent(PollVoteCastedEventDTO)
    case typePollVoteChangedEvent(PollVoteChangedEventDTO)
    case typePollVoteRemovedEvent(PollVoteRemovedEventDTO)
    case typeReactionDeletedEvent(ReactionDeletedEventDTO)
    case typeReactionNewEvent(ReactionNewEventDTO)
    case typeReactionUpdatedEvent(ReactionUpdatedEventDTO)
    case typeReminderCreatedEvent(ReminderCreatedEventDTO)
    case typeReminderDeletedEvent(ReminderDeletedEventDTO)
    case typeReminderUpdatedEvent(ReminderUpdatedEventDTO)
    case typeThreadUpdatedEvent(ThreadUpdatedEventDTO)
    case typeTypingStartEvent(TypingStartEventDTO)
    case typeTypingStopEvent(TypingStopEventDTO)
    case typeUserBannedEvent(UserBannedEventDTO)
    case typeUserMessagesDeletedEvent(UserMessagesDeletedEventDTO)
    case typeUserPresenceChangedEvent(UserPresenceChangedEventDTO)
    case typeUserUnbannedEvent(UserUnbannedEventDTO)
    case typeUserUpdatedEvent(UserUpdatedEventDTO)
    case typeUserWatchingStartEvent(UserWatchingStartEventDTO)
    case typeUserWatchingStopEvent(UserWatchingStopEventDTO)

    var type: String {
        switch self {
        case .typeAIIndicatorClearEvent(let value):
            return value.type
        case .typeAIIndicatorStopEvent(let value):
            return value.type
        case .typeAIIndicatorUpdateEvent(let value):
            return value.type
        case .typeChannelDeletedEvent(let value):
            return value.type
        case .typeChannelHiddenEvent(let value):
            return value.type
        case .typeChannelTruncatedEvent(let value):
            return value.type
        case .typeChannelUpdatedEvent(let value):
            return value.type
        case .typeChannelVisibleEvent(let value):
            return value.type
        case .typeDraftDeletedEvent(let value):
            return value.type
        case .typeDraftUpdatedEvent(let value):
            return value.type
        case .typeHealthCheckEvent(let value):
            return value.type
        case .typeMemberAddedEvent(let value):
            return value.type
        case .typeMemberRemovedEvent(let value):
            return value.type
        case .typeMemberUpdatedEvent(let value):
            return value.type
        case .typeMessageDeletedEvent(let value):
            return value.type
        case .typeMessageDeliveredEvent(let value):
            return value.type
        case .typeMessageNewEvent(let value):
            return value.type
        case .typeMessageReadEvent(let value):
            return value.type
        case .typeMessageUpdatedEvent(let value):
            return value.type
        case .typeNotificationAddedToChannelEvent(let value):
            return value.type
        case .typeNotificationChannelDeletedEvent(let value):
            return value.type
        case .typeNotificationChannelMutesUpdatedEvent(let value):
            return value.type
        case .typeNotificationInviteAcceptedEvent(let value):
            return value.type
        case .typeNotificationInviteRejectedEvent(let value):
            return value.type
        case .typeNotificationInvitedEvent(let value):
            return value.type
        case .typeNotificationMarkReadEvent(let value):
            return value.type
        case .typeNotificationMarkUnreadEvent(let value):
            return value.type
        case .typeNotificationNewMessageEvent(let value):
            return value.type
        case .typeNotificationMutesUpdatedEvent(let value):
            return value.type
        case .typeReminderNotificationEvent(let value):
            return value.type
        case .typeNotificationRemovedFromChannelEvent(let value):
            return value.type
        case .typeNotificationThreadMessageNewEvent(let value):
            return value.type
        case .typePollClosedEvent(let value):
            return value.type
        case .typePollDeletedEvent(let value):
            return value.type
        case .typePollUpdatedEvent(let value):
            return value.type
        case .typePollVoteCastedEvent(let value):
            return value.type
        case .typePollVoteChangedEvent(let value):
            return value.type
        case .typePollVoteRemovedEvent(let value):
            return value.type
        case .typeReactionDeletedEvent(let value):
            return value.type
        case .typeReactionNewEvent(let value):
            return value.type
        case .typeReactionUpdatedEvent(let value):
            return value.type
        case .typeReminderCreatedEvent(let value):
            return value.type
        case .typeReminderDeletedEvent(let value):
            return value.type
        case .typeReminderUpdatedEvent(let value):
            return value.type
        case .typeThreadUpdatedEvent(let value):
            return value.type
        case .typeTypingStartEvent(let value):
            return value.type
        case .typeTypingStopEvent(let value):
            return value.type
        case .typeUserBannedEvent(let value):
            return value.type
        case .typeUserMessagesDeletedEvent(let value):
            return value.type
        case .typeUserPresenceChangedEvent(let value):
            return value.type
        case .typeUserUnbannedEvent(let value):
            return value.type
        case .typeUserUpdatedEvent(let value):
            return value.type
        case .typeUserWatchingStartEvent(let value):
            return value.type
        case .typeUserWatchingStopEvent(let value):
            return value.type
        }
    }

    var rawValue: EventDTO {
        switch self {
        case .typeAIIndicatorClearEvent(let value):
            return value
        case .typeAIIndicatorStopEvent(let value):
            return value
        case .typeAIIndicatorUpdateEvent(let value):
            return value
        case .typeChannelDeletedEvent(let value):
            return value
        case .typeChannelHiddenEvent(let value):
            return value
        case .typeChannelTruncatedEvent(let value):
            return value
        case .typeChannelUpdatedEvent(let value):
            return value
        case .typeChannelVisibleEvent(let value):
            return value
        case .typeDraftDeletedEvent(let value):
            return value
        case .typeDraftUpdatedEvent(let value):
            return value
        case .typeHealthCheckEvent(let value):
            return value
        case .typeMemberAddedEvent(let value):
            return value
        case .typeMemberRemovedEvent(let value):
            return value
        case .typeMemberUpdatedEvent(let value):
            return value
        case .typeMessageDeletedEvent(let value):
            return value
        case .typeMessageDeliveredEvent(let value):
            return value
        case .typeMessageNewEvent(let value):
            return value
        case .typeMessageReadEvent(let value):
            return value
        case .typeMessageUpdatedEvent(let value):
            return value
        case .typeNotificationAddedToChannelEvent(let value):
            return value
        case .typeNotificationChannelDeletedEvent(let value):
            return value
        case .typeNotificationChannelMutesUpdatedEvent(let value):
            return value
        case .typeNotificationInviteAcceptedEvent(let value):
            return value
        case .typeNotificationInviteRejectedEvent(let value):
            return value
        case .typeNotificationInvitedEvent(let value):
            return value
        case .typeNotificationMarkReadEvent(let value):
            return value
        case .typeNotificationMarkUnreadEvent(let value):
            return value
        case .typeNotificationNewMessageEvent(let value):
            return value
        case .typeNotificationMutesUpdatedEvent(let value):
            return value
        case .typeReminderNotificationEvent(let value):
            return value
        case .typeNotificationRemovedFromChannelEvent(let value):
            return value
        case .typeNotificationThreadMessageNewEvent(let value):
            return value
        case .typePollClosedEvent(let value):
            return value
        case .typePollDeletedEvent(let value):
            return value
        case .typePollUpdatedEvent(let value):
            return value
        case .typePollVoteCastedEvent(let value):
            return value
        case .typePollVoteChangedEvent(let value):
            return value
        case .typePollVoteRemovedEvent(let value):
            return value
        case .typeReactionDeletedEvent(let value):
            return value
        case .typeReactionNewEvent(let value):
            return value
        case .typeReactionUpdatedEvent(let value):
            return value
        case .typeReminderCreatedEvent(let value):
            return value
        case .typeReminderDeletedEvent(let value):
            return value
        case .typeReminderUpdatedEvent(let value):
            return value
        case .typeThreadUpdatedEvent(let value):
            return value
        case .typeTypingStartEvent(let value):
            return value
        case .typeTypingStopEvent(let value):
            return value
        case .typeUserBannedEvent(let value):
            return value
        case .typeUserMessagesDeletedEvent(let value):
            return value
        case .typeUserPresenceChangedEvent(let value):
            return value
        case .typeUserUnbannedEvent(let value):
            return value
        case .typeUserUpdatedEvent(let value):
            return value
        case .typeUserWatchingStartEvent(let value):
            return value
        case .typeUserWatchingStopEvent(let value):
            return value
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dto = try container.decode(WSEventMapping.self)
        if dto.type == "ai_indicator.clear" {
            let value = try container.decode(AIIndicatorClearEventDTO.self)
            self = .typeAIIndicatorClearEvent(value)
        } else if dto.type == "ai_indicator.stop" {
            let value = try container.decode(AIIndicatorStopEventDTO.self)
            self = .typeAIIndicatorStopEvent(value)
        } else if dto.type == "ai_indicator.update" {
            let value = try container.decode(AIIndicatorUpdateEventDTO.self)
            self = .typeAIIndicatorUpdateEvent(value)
        } else if dto.type == "channel.deleted" {
            let value = try container.decode(ChannelDeletedEventDTO.self)
            self = .typeChannelDeletedEvent(value)
        } else if dto.type == "channel.hidden" {
            let value = try container.decode(ChannelHiddenEventDTO.self)
            self = .typeChannelHiddenEvent(value)
        } else if dto.type == "channel.truncated" {
            let value = try container.decode(ChannelTruncatedEventDTO.self)
            self = .typeChannelTruncatedEvent(value)
        } else if dto.type == "channel.updated" {
            let value = try container.decode(ChannelUpdatedEventDTO.self)
            self = .typeChannelUpdatedEvent(value)
        } else if dto.type == "channel.visible" {
            let value = try container.decode(ChannelVisibleEventDTO.self)
            self = .typeChannelVisibleEvent(value)
        } else if dto.type == "draft.deleted" {
            let value = try container.decode(DraftDeletedEventDTO.self)
            self = .typeDraftDeletedEvent(value)
        } else if dto.type == "draft.updated" {
            let value = try container.decode(DraftUpdatedEventDTO.self)
            self = .typeDraftUpdatedEvent(value)
        } else if dto.type == "health.check" {
            let value = try container.decode(HealthCheckEventDTO.self)
            self = .typeHealthCheckEvent(value)
        } else if dto.type == "member.added" {
            let value = try container.decode(MemberAddedEventDTO.self)
            self = .typeMemberAddedEvent(value)
        } else if dto.type == "member.removed" {
            let value = try container.decode(MemberRemovedEventDTO.self)
            self = .typeMemberRemovedEvent(value)
        } else if dto.type == "member.updated" {
            let value = try container.decode(MemberUpdatedEventDTO.self)
            self = .typeMemberUpdatedEvent(value)
        } else if dto.type == "message.deleted" {
            let value = try container.decode(MessageDeletedEventDTO.self)
            self = .typeMessageDeletedEvent(value)
        } else if dto.type == "message.delivered" {
            let value = try container.decode(MessageDeliveredEventDTO.self)
            self = .typeMessageDeliveredEvent(value)
        } else if dto.type == "message.new" {
            let value = try container.decode(MessageNewEventDTO.self)
            self = .typeMessageNewEvent(value)
        } else if dto.type == "message.read" {
            let value = try container.decode(MessageReadEventDTO.self)
            self = .typeMessageReadEvent(value)
        } else if dto.type == "message.updated" {
            let value = try container.decode(MessageUpdatedEventDTO.self)
            self = .typeMessageUpdatedEvent(value)
        } else if dto.type == "notification.added_to_channel" {
            let value = try container.decode(NotificationAddedToChannelEventDTO.self)
            self = .typeNotificationAddedToChannelEvent(value)
        } else if dto.type == "notification.channel_deleted" {
            let value = try container.decode(NotificationChannelDeletedEventDTO.self)
            self = .typeNotificationChannelDeletedEvent(value)
        } else if dto.type == "notification.channel_mutes_updated" {
            let value = try container.decode(NotificationChannelMutesUpdatedEventDTO.self)
            self = .typeNotificationChannelMutesUpdatedEvent(value)
        } else if dto.type == "notification.invite_accepted" {
            let value = try container.decode(NotificationInviteAcceptedEventDTO.self)
            self = .typeNotificationInviteAcceptedEvent(value)
        } else if dto.type == "notification.invite_rejected" {
            let value = try container.decode(NotificationInviteRejectedEventDTO.self)
            self = .typeNotificationInviteRejectedEvent(value)
        } else if dto.type == "notification.invited" {
            let value = try container.decode(NotificationInvitedEventDTO.self)
            self = .typeNotificationInvitedEvent(value)
        } else if dto.type == "notification.mark_read" {
            let value = try container.decode(NotificationMarkReadEventDTO.self)
            self = .typeNotificationMarkReadEvent(value)
        } else if dto.type == "notification.mark_unread" {
            let value = try container.decode(NotificationMarkUnreadEventDTO.self)
            self = .typeNotificationMarkUnreadEvent(value)
        } else if dto.type == "notification.message_new" {
            let value = try container.decode(NotificationNewMessageEventDTO.self)
            self = .typeNotificationNewMessageEvent(value)
        } else if dto.type == "notification.mutes_updated" {
            let value = try container.decode(NotificationMutesUpdatedEventDTO.self)
            self = .typeNotificationMutesUpdatedEvent(value)
        } else if dto.type == "notification.reminder_due" {
            let value = try container.decode(ReminderNotificationEventDTO.self)
            self = .typeReminderNotificationEvent(value)
        } else if dto.type == "notification.removed_from_channel" {
            let value = try container.decode(NotificationRemovedFromChannelEventDTO.self)
            self = .typeNotificationRemovedFromChannelEvent(value)
        } else if dto.type == "notification.thread_message_new" {
            let value = try container.decode(NotificationThreadMessageNewEventDTO.self)
            self = .typeNotificationThreadMessageNewEvent(value)
        } else if dto.type == "poll.closed" {
            let value = try container.decode(PollClosedEventDTO.self)
            self = .typePollClosedEvent(value)
        } else if dto.type == "poll.deleted" {
            let value = try container.decode(PollDeletedEventDTO.self)
            self = .typePollDeletedEvent(value)
        } else if dto.type == "poll.updated" {
            let value = try container.decode(PollUpdatedEventDTO.self)
            self = .typePollUpdatedEvent(value)
        } else if dto.type == "poll.vote_casted" {
            let value = try container.decode(PollVoteCastedEventDTO.self)
            self = .typePollVoteCastedEvent(value)
        } else if dto.type == "poll.vote_changed" {
            let value = try container.decode(PollVoteChangedEventDTO.self)
            self = .typePollVoteChangedEvent(value)
        } else if dto.type == "poll.vote_removed" {
            let value = try container.decode(PollVoteRemovedEventDTO.self)
            self = .typePollVoteRemovedEvent(value)
        } else if dto.type == "reaction.deleted" {
            let value = try container.decode(ReactionDeletedEventDTO.self)
            self = .typeReactionDeletedEvent(value)
        } else if dto.type == "reaction.new" {
            let value = try container.decode(ReactionNewEventDTO.self)
            self = .typeReactionNewEvent(value)
        } else if dto.type == "reaction.updated" {
            let value = try container.decode(ReactionUpdatedEventDTO.self)
            self = .typeReactionUpdatedEvent(value)
        } else if dto.type == "reminder.created" {
            let value = try container.decode(ReminderCreatedEventDTO.self)
            self = .typeReminderCreatedEvent(value)
        } else if dto.type == "reminder.deleted" {
            let value = try container.decode(ReminderDeletedEventDTO.self)
            self = .typeReminderDeletedEvent(value)
        } else if dto.type == "reminder.updated" {
            let value = try container.decode(ReminderUpdatedEventDTO.self)
            self = .typeReminderUpdatedEvent(value)
        } else if dto.type == "thread.updated" {
            let value = try container.decode(ThreadUpdatedEventDTO.self)
            self = .typeThreadUpdatedEvent(value)
        } else if dto.type == "typing.start" {
            let value = try container.decode(TypingStartEventDTO.self)
            self = .typeTypingStartEvent(value)
        } else if dto.type == "typing.stop" {
            let value = try container.decode(TypingStopEventDTO.self)
            self = .typeTypingStopEvent(value)
        } else if dto.type == "user.banned" {
            let value = try container.decode(UserBannedEventDTO.self)
            self = .typeUserBannedEvent(value)
        } else if dto.type == "user.messages.deleted" {
            let value = try container.decode(UserMessagesDeletedEventDTO.self)
            self = .typeUserMessagesDeletedEvent(value)
        } else if dto.type == "user.presence.changed" {
            let value = try container.decode(UserPresenceChangedEventDTO.self)
            self = .typeUserPresenceChangedEvent(value)
        } else if dto.type == "user.unbanned" {
            let value = try container.decode(UserUnbannedEventDTO.self)
            self = .typeUserUnbannedEvent(value)
        } else if dto.type == "user.updated" {
            let value = try container.decode(UserUpdatedEventDTO.self)
            self = .typeUserUpdatedEvent(value)
        } else if dto.type == "user.watching.start" {
            let value = try container.decode(UserWatchingStartEventDTO.self)
            self = .typeUserWatchingStartEvent(value)
        } else if dto.type == "user.watching.stop" {
            let value = try container.decode(UserWatchingStopEventDTO.self)
            self = .typeUserWatchingStopEvent(value)
        } else {
            throw DecodingError.typeMismatch(
                Self.Type.self,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unable to decode instance of WSEvent"
                )
            )
        }
    }
}
