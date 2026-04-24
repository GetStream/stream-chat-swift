//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

private class WSEventMapping: Decodable {
    let type: String
}

enum WSClientEvent: Codable, Hashable {
    case typeCustomEvent(CustomEvent)
    case typeAIIndicatorClearEvent(AIIndicatorClearEventModel)
    case typeAIIndicatorStopEvent(AIIndicatorStopEventModel)
    case typeAIIndicatorUpdateEvent(AIIndicatorUpdateEventModel)
    case typeAppUpdatedEvent(AppUpdatedEvent)
    case typeChannelCreatedEvent(ChannelCreatedEvent)
    case typeChannelDeletedEvent(ChannelDeletedEventModel)
    case typeChannelFrozenEvent(ChannelFrozenEvent)
    case typeChannelHiddenEvent(ChannelHiddenEventModel)
    case typeChannelKickedEvent(ChannelKickedEvent)
    case typeMaxStreakChangedEvent(MaxStreakChangedEvent)
    case typeChannelTruncatedEvent(ChannelTruncatedEventModel)
    case typeChannelUnFrozenEvent(ChannelUnFrozenEvent)
    case typeChannelUpdatedEvent(ChannelUpdatedEventModel)
    case typeChannelVisibleEvent(ChannelVisibleEventModel)
    case typeDraftDeletedEvent(DraftDeletedEventModel)
    case typeDraftUpdatedEvent(DraftUpdatedEventModel)
    case typeHealthCheckEvent(HealthCheckEventModel)
    case typeMemberAddedEvent(MemberAddedEventModel)
    case typeMemberRemovedEvent(MemberRemovedEventModel)
    case typeMemberUpdatedEvent(MemberUpdatedEventModel)
    case typeMessageDeletedEvent(MessageDeletedEventModel)
    case typeMessageDeliveredEvent(MessageDeliveredEventModel)
    case typeMessageNewEvent(MessageNewEventModel)
    case typePendingMessageEvent(PendingMessageEvent)
    case typeMessageReadEvent(MessageReadEventModel)
    case typeMessageUndeletedEvent(MessageUndeletedEvent)
    case typeMessageUpdatedEvent(MessageUpdatedEventModel)
    case typeModerationCustomActionEvent(ModerationCustomActionEvent)
    case typeModerationFlaggedEvent(ModerationFlaggedEvent)
    case typeModerationMarkReviewedEvent(ModerationMarkReviewedEvent)
    case typeNotificationAddedToChannelEvent(NotificationAddedToChannelEventModel)
    case typeNotificationChannelDeletedEvent(NotificationChannelDeletedEventModel)
    case typeNotificationChannelMutesUpdatedEvent(NotificationChannelMutesUpdatedEventModel)
    case typeNotificationChannelTruncatedEvent(NotificationChannelTruncatedEvent)
    case typeNotificationInviteAcceptedEvent(NotificationInviteAcceptedEventModel)
    case typeNotificationInviteRejectedEvent(NotificationInviteRejectedEventModel)
    case typeNotificationInvitedEvent(NotificationInvitedEventModel)
    case typeNotificationMarkReadEvent(NotificationMarkReadEventModel)
    case typeNotificationMarkUnreadEvent(NotificationMarkUnreadEventModel)
    case typeNotificationNewMessageEvent(NotificationNewMessageEvent)
    case typeNotificationMutesUpdatedEvent(NotificationMutesUpdatedEventModel)
    case typeReminderNotificationEvent(ReminderNotificationEvent)
    case typeNotificationRemovedFromChannelEvent(NotificationRemovedFromChannelEventModel)
    case typeNotificationThreadMessageNewEvent(NotificationThreadMessageNewEvent)
    case typePollClosedEvent(PollClosedEventModel)
    case typePollDeletedEvent(PollDeletedEventModel)
    case typePollUpdatedEvent(PollUpdatedEventModel)
    case typePollVoteCastedEvent(PollVoteCastedEventModel)
    case typePollVoteChangedEvent(PollVoteChangedEventModel)
    case typePollVoteRemovedEvent(PollVoteRemovedEventModel)
    case typeReactionDeletedEvent(ReactionDeletedEventModel)
    case typeReactionNewEvent(ReactionNewEventModel)
    case typeReactionUpdatedEvent(ReactionUpdatedEventModel)
    case typeReminderCreatedEvent(ReminderCreatedEvent)
    case typeReminderDeletedEvent(ReminderDeletedEvent)
    case typeReminderUpdatedEvent(ReminderUpdatedEvent)
    case typeThreadUpdatedEvent(ThreadUpdatedEventModel)
    case typeTypingStartEvent(TypingStartEvent)
    case typeTypingStopEvent(TypingStopEvent)
    case typeUserBannedEvent(UserBannedEventModel)
    case typeUserDeactivatedEvent(UserDeactivatedEvent)
    case typeUserDeletedEvent(UserDeletedEvent)
    case typeUserMessagesDeletedEvent(UserMessagesDeletedEventModel)
    case typeUserMutedEvent(UserMutedEvent)
    case typeUserPresenceChangedEvent(UserPresenceChangedEventModel)
    case typeUserReactivatedEvent(UserReactivatedEvent)
    case typeUserUnbannedEvent(UserUnbannedEventModel)
    case typeUserUpdatedEvent(UserUpdatedEventModel)
    case typeUserWatchingStartEvent(UserWatchingStartEvent)
    case typeUserWatchingStopEvent(UserWatchingStopEvent)
    case typeUserGroupCreatedEvent(UserGroupCreatedEvent)
    case typeUserGroupDeletedEvent(UserGroupDeletedEvent)
    case typeUserGroupMemberAddedEvent(UserGroupMemberAddedEvent)
    case typeUserGroupMemberRemovedEvent(UserGroupMemberRemovedEvent)
    case typeUserGroupUpdatedEvent(UserGroupUpdatedEvent)

    var type: String {
        switch self {
        case .typeCustomEvent(let value):
            return value.type
        case .typeAIIndicatorClearEvent(let value):
            return value.type
        case .typeAIIndicatorStopEvent(let value):
            return value.type
        case .typeAIIndicatorUpdateEvent(let value):
            return value.type
        case .typeAppUpdatedEvent(let value):
            return value.type
        case .typeChannelCreatedEvent(let value):
            return value.type
        case .typeChannelDeletedEvent(let value):
            return value.type
        case .typeChannelFrozenEvent(let value):
            return value.type
        case .typeChannelHiddenEvent(let value):
            return value.type
        case .typeChannelKickedEvent(let value):
            return value.type
        case .typeMaxStreakChangedEvent(let value):
            return value.type
        case .typeChannelTruncatedEvent(let value):
            return value.type
        case .typeChannelUnFrozenEvent(let value):
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
        case .typePendingMessageEvent(let value):
            return value.type
        case .typeMessageReadEvent(let value):
            return value.type
        case .typeMessageUndeletedEvent(let value):
            return value.type
        case .typeMessageUpdatedEvent(let value):
            return value.type
        case .typeModerationCustomActionEvent(let value):
            return value.type
        case .typeModerationFlaggedEvent(let value):
            return value.type
        case .typeModerationMarkReviewedEvent(let value):
            return value.type
        case .typeNotificationAddedToChannelEvent(let value):
            return value.type
        case .typeNotificationChannelDeletedEvent(let value):
            return value.type
        case .typeNotificationChannelMutesUpdatedEvent(let value):
            return value.type
        case .typeNotificationChannelTruncatedEvent(let value):
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
        case .typeUserDeactivatedEvent(let value):
            return value.type
        case .typeUserDeletedEvent(let value):
            return value.type
        case .typeUserMessagesDeletedEvent(let value):
            return value.type
        case .typeUserMutedEvent(let value):
            return value.type
        case .typeUserPresenceChangedEvent(let value):
            return value.type
        case .typeUserReactivatedEvent(let value):
            return value.type
        case .typeUserUnbannedEvent(let value):
            return value.type
        case .typeUserUpdatedEvent(let value):
            return value.type
        case .typeUserWatchingStartEvent(let value):
            return value.type
        case .typeUserWatchingStopEvent(let value):
            return value.type
        case .typeUserGroupCreatedEvent(let value):
            return value.type
        case .typeUserGroupDeletedEvent(let value):
            return value.type
        case .typeUserGroupMemberAddedEvent(let value):
            return value.type
        case .typeUserGroupMemberRemovedEvent(let value):
            return value.type
        case .typeUserGroupUpdatedEvent(let value):
            return value.type
        }
    }

    var rawValue: Event {
        switch self {
        case .typeCustomEvent(let value):
            return value
        case .typeAIIndicatorClearEvent(let value):
            return value
        case .typeAIIndicatorStopEvent(let value):
            return value
        case .typeAIIndicatorUpdateEvent(let value):
            return value
        case .typeAppUpdatedEvent(let value):
            return value
        case .typeChannelCreatedEvent(let value):
            return value
        case .typeChannelDeletedEvent(let value):
            return value
        case .typeChannelFrozenEvent(let value):
            return value
        case .typeChannelHiddenEvent(let value):
            return value
        case .typeChannelKickedEvent(let value):
            return value
        case .typeMaxStreakChangedEvent(let value):
            return value
        case .typeChannelTruncatedEvent(let value):
            return value
        case .typeChannelUnFrozenEvent(let value):
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
        case .typePendingMessageEvent(let value):
            return value
        case .typeMessageReadEvent(let value):
            return value
        case .typeMessageUndeletedEvent(let value):
            return value
        case .typeMessageUpdatedEvent(let value):
            return value
        case .typeModerationCustomActionEvent(let value):
            return value
        case .typeModerationFlaggedEvent(let value):
            return value
        case .typeModerationMarkReviewedEvent(let value):
            return value
        case .typeNotificationAddedToChannelEvent(let value):
            return value
        case .typeNotificationChannelDeletedEvent(let value):
            return value
        case .typeNotificationChannelMutesUpdatedEvent(let value):
            return value
        case .typeNotificationChannelTruncatedEvent(let value):
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
        case .typeUserDeactivatedEvent(let value):
            return value
        case .typeUserDeletedEvent(let value):
            return value
        case .typeUserMessagesDeletedEvent(let value):
            return value
        case .typeUserMutedEvent(let value):
            return value
        case .typeUserPresenceChangedEvent(let value):
            return value
        case .typeUserReactivatedEvent(let value):
            return value
        case .typeUserUnbannedEvent(let value):
            return value
        case .typeUserUpdatedEvent(let value):
            return value
        case .typeUserWatchingStartEvent(let value):
            return value
        case .typeUserWatchingStopEvent(let value):
            return value
        case .typeUserGroupCreatedEvent(let value):
            return value
        case .typeUserGroupDeletedEvent(let value):
            return value
        case .typeUserGroupMemberAddedEvent(let value):
            return value
        case .typeUserGroupMemberRemovedEvent(let value):
            return value
        case .typeUserGroupUpdatedEvent(let value):
            return value
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .typeCustomEvent(let value):
            try container.encode(value)
        case .typeAIIndicatorClearEvent(let value):
            try container.encode(value)
        case .typeAIIndicatorStopEvent(let value):
            try container.encode(value)
        case .typeAIIndicatorUpdateEvent(let value):
            try container.encode(value)
        case .typeAppUpdatedEvent(let value):
            try container.encode(value)
        case .typeChannelCreatedEvent(let value):
            try container.encode(value)
        case .typeChannelDeletedEvent(let value):
            try container.encode(value)
        case .typeChannelFrozenEvent(let value):
            try container.encode(value)
        case .typeChannelHiddenEvent(let value):
            try container.encode(value)
        case .typeChannelKickedEvent(let value):
            try container.encode(value)
        case .typeMaxStreakChangedEvent(let value):
            try container.encode(value)
        case .typeChannelTruncatedEvent(let value):
            try container.encode(value)
        case .typeChannelUnFrozenEvent(let value):
            try container.encode(value)
        case .typeChannelUpdatedEvent(let value):
            try container.encode(value)
        case .typeChannelVisibleEvent(let value):
            try container.encode(value)
        case .typeDraftDeletedEvent(let value):
            try container.encode(value)
        case .typeDraftUpdatedEvent(let value):
            try container.encode(value)
        case .typeHealthCheckEvent(let value):
            try container.encode(value)
        case .typeMemberAddedEvent(let value):
            try container.encode(value)
        case .typeMemberRemovedEvent(let value):
            try container.encode(value)
        case .typeMemberUpdatedEvent(let value):
            try container.encode(value)
        case .typeMessageDeletedEvent(let value):
            try container.encode(value)
        case .typeMessageDeliveredEvent(let value):
            try container.encode(value)
        case .typeMessageNewEvent(let value):
            try container.encode(value)
        case .typePendingMessageEvent(let value):
            try container.encode(value)
        case .typeMessageReadEvent(let value):
            try container.encode(value)
        case .typeMessageUndeletedEvent(let value):
            try container.encode(value)
        case .typeMessageUpdatedEvent(let value):
            try container.encode(value)
        case .typeModerationCustomActionEvent(let value):
            try container.encode(value)
        case .typeModerationFlaggedEvent(let value):
            try container.encode(value)
        case .typeModerationMarkReviewedEvent(let value):
            try container.encode(value)
        case .typeNotificationAddedToChannelEvent(let value):
            try container.encode(value)
        case .typeNotificationChannelDeletedEvent(let value):
            try container.encode(value)
        case .typeNotificationChannelMutesUpdatedEvent(let value):
            try container.encode(value)
        case .typeNotificationChannelTruncatedEvent(let value):
            try container.encode(value)
        case .typeNotificationInviteAcceptedEvent(let value):
            try container.encode(value)
        case .typeNotificationInviteRejectedEvent(let value):
            try container.encode(value)
        case .typeNotificationInvitedEvent(let value):
            try container.encode(value)
        case .typeNotificationMarkReadEvent(let value):
            try container.encode(value)
        case .typeNotificationMarkUnreadEvent(let value):
            try container.encode(value)
        case .typeNotificationNewMessageEvent(let value):
            try container.encode(value)
        case .typeNotificationMutesUpdatedEvent(let value):
            try container.encode(value)
        case .typeReminderNotificationEvent(let value):
            try container.encode(value)
        case .typeNotificationRemovedFromChannelEvent(let value):
            try container.encode(value)
        case .typeNotificationThreadMessageNewEvent(let value):
            try container.encode(value)
        case .typePollClosedEvent(let value):
            try container.encode(value)
        case .typePollDeletedEvent(let value):
            try container.encode(value)
        case .typePollUpdatedEvent(let value):
            try container.encode(value)
        case .typePollVoteCastedEvent(let value):
            try container.encode(value)
        case .typePollVoteChangedEvent(let value):
            try container.encode(value)
        case .typePollVoteRemovedEvent(let value):
            try container.encode(value)
        case .typeReactionDeletedEvent(let value):
            try container.encode(value)
        case .typeReactionNewEvent(let value):
            try container.encode(value)
        case .typeReactionUpdatedEvent(let value):
            try container.encode(value)
        case .typeReminderCreatedEvent(let value):
            try container.encode(value)
        case .typeReminderDeletedEvent(let value):
            try container.encode(value)
        case .typeReminderUpdatedEvent(let value):
            try container.encode(value)
        case .typeThreadUpdatedEvent(let value):
            try container.encode(value)
        case .typeTypingStartEvent(let value):
            try container.encode(value)
        case .typeTypingStopEvent(let value):
            try container.encode(value)
        case .typeUserBannedEvent(let value):
            try container.encode(value)
        case .typeUserDeactivatedEvent(let value):
            try container.encode(value)
        case .typeUserDeletedEvent(let value):
            try container.encode(value)
        case .typeUserMessagesDeletedEvent(let value):
            try container.encode(value)
        case .typeUserMutedEvent(let value):
            try container.encode(value)
        case .typeUserPresenceChangedEvent(let value):
            try container.encode(value)
        case .typeUserReactivatedEvent(let value):
            try container.encode(value)
        case .typeUserUnbannedEvent(let value):
            try container.encode(value)
        case .typeUserUpdatedEvent(let value):
            try container.encode(value)
        case .typeUserWatchingStartEvent(let value):
            try container.encode(value)
        case .typeUserWatchingStopEvent(let value):
            try container.encode(value)
        case .typeUserGroupCreatedEvent(let value):
            try container.encode(value)
        case .typeUserGroupDeletedEvent(let value):
            try container.encode(value)
        case .typeUserGroupMemberAddedEvent(let value):
            try container.encode(value)
        case .typeUserGroupMemberRemovedEvent(let value):
            try container.encode(value)
        case .typeUserGroupUpdatedEvent(let value):
            try container.encode(value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dto = try container.decode(WSEventMapping.self)
        if dto.type == "*" {
            let value = try container.decode(CustomEvent.self)
            self = .typeCustomEvent(value)
        } else if dto.type == "ai_indicator.clear" {
            let value = try container.decode(AIIndicatorClearEventModel.self)
            self = .typeAIIndicatorClearEvent(value)
        } else if dto.type == "ai_indicator.stop" {
            let value = try container.decode(AIIndicatorStopEventModel.self)
            self = .typeAIIndicatorStopEvent(value)
        } else if dto.type == "ai_indicator.update" {
            let value = try container.decode(AIIndicatorUpdateEventModel.self)
            self = .typeAIIndicatorUpdateEvent(value)
        } else if dto.type == "app.updated" {
            let value = try container.decode(AppUpdatedEvent.self)
            self = .typeAppUpdatedEvent(value)
        } else if dto.type == "channel.created" {
            let value = try container.decode(ChannelCreatedEvent.self)
            self = .typeChannelCreatedEvent(value)
        } else if dto.type == "channel.deleted" {
            let value = try container.decode(ChannelDeletedEventModel.self)
            self = .typeChannelDeletedEvent(value)
        } else if dto.type == "channel.frozen" {
            let value = try container.decode(ChannelFrozenEvent.self)
            self = .typeChannelFrozenEvent(value)
        } else if dto.type == "channel.hidden" {
            let value = try container.decode(ChannelHiddenEventModel.self)
            self = .typeChannelHiddenEvent(value)
        } else if dto.type == "channel.kicked" {
            let value = try container.decode(ChannelKickedEvent.self)
            self = .typeChannelKickedEvent(value)
        } else if dto.type == "channel.max_streak_changed" {
            let value = try container.decode(MaxStreakChangedEvent.self)
            self = .typeMaxStreakChangedEvent(value)
        } else if dto.type == "channel.truncated" {
            let value = try container.decode(ChannelTruncatedEventModel.self)
            self = .typeChannelTruncatedEvent(value)
        } else if dto.type == "channel.unfrozen" {
            let value = try container.decode(ChannelUnFrozenEvent.self)
            self = .typeChannelUnFrozenEvent(value)
        } else if dto.type == "channel.updated" {
            let value = try container.decode(ChannelUpdatedEventModel.self)
            self = .typeChannelUpdatedEvent(value)
        } else if dto.type == "channel.visible" {
            let value = try container.decode(ChannelVisibleEventModel.self)
            self = .typeChannelVisibleEvent(value)
        } else if dto.type == "draft.deleted" {
            let value = try container.decode(DraftDeletedEventModel.self)
            self = .typeDraftDeletedEvent(value)
        } else if dto.type == "draft.updated" {
            let value = try container.decode(DraftUpdatedEventModel.self)
            self = .typeDraftUpdatedEvent(value)
        } else if dto.type == "health.check" {
            let value = try container.decode(HealthCheckEventModel.self)
            self = .typeHealthCheckEvent(value)
        } else if dto.type == "member.added" {
            let value = try container.decode(MemberAddedEventModel.self)
            self = .typeMemberAddedEvent(value)
        } else if dto.type == "member.removed" {
            let value = try container.decode(MemberRemovedEventModel.self)
            self = .typeMemberRemovedEvent(value)
        } else if dto.type == "member.updated" {
            let value = try container.decode(MemberUpdatedEventModel.self)
            self = .typeMemberUpdatedEvent(value)
        } else if dto.type == "message.deleted" {
            let value = try container.decode(MessageDeletedEventModel.self)
            self = .typeMessageDeletedEvent(value)
        } else if dto.type == "message.delivered" {
            let value = try container.decode(MessageDeliveredEventModel.self)
            self = .typeMessageDeliveredEvent(value)
        } else if dto.type == "message.new" {
            let value = try container.decode(MessageNewEventModel.self)
            self = .typeMessageNewEvent(value)
        } else if dto.type == "message.pending" {
            let value = try container.decode(PendingMessageEvent.self)
            self = .typePendingMessageEvent(value)
        } else if dto.type == "message.read" {
            let value = try container.decode(MessageReadEventModel.self)
            self = .typeMessageReadEvent(value)
        } else if dto.type == "message.undeleted" {
            let value = try container.decode(MessageUndeletedEvent.self)
            self = .typeMessageUndeletedEvent(value)
        } else if dto.type == "message.updated" {
            let value = try container.decode(MessageUpdatedEventModel.self)
            self = .typeMessageUpdatedEvent(value)
        } else if dto.type == "moderation.custom_action" {
            let value = try container.decode(ModerationCustomActionEvent.self)
            self = .typeModerationCustomActionEvent(value)
        } else if dto.type == "moderation.flagged" {
            let value = try container.decode(ModerationFlaggedEvent.self)
            self = .typeModerationFlaggedEvent(value)
        } else if dto.type == "moderation.mark_reviewed" {
            let value = try container.decode(ModerationMarkReviewedEvent.self)
            self = .typeModerationMarkReviewedEvent(value)
        } else if dto.type == "notification.added_to_channel" {
            let value = try container.decode(NotificationAddedToChannelEventModel.self)
            self = .typeNotificationAddedToChannelEvent(value)
        } else if dto.type == "notification.channel_deleted" {
            let value = try container.decode(NotificationChannelDeletedEventModel.self)
            self = .typeNotificationChannelDeletedEvent(value)
        } else if dto.type == "notification.channel_mutes_updated" {
            let value = try container.decode(NotificationChannelMutesUpdatedEventModel.self)
            self = .typeNotificationChannelMutesUpdatedEvent(value)
        } else if dto.type == "notification.channel_truncated" {
            let value = try container.decode(NotificationChannelTruncatedEvent.self)
            self = .typeNotificationChannelTruncatedEvent(value)
        } else if dto.type == "notification.invite_accepted" {
            let value = try container.decode(NotificationInviteAcceptedEventModel.self)
            self = .typeNotificationInviteAcceptedEvent(value)
        } else if dto.type == "notification.invite_rejected" {
            let value = try container.decode(NotificationInviteRejectedEventModel.self)
            self = .typeNotificationInviteRejectedEvent(value)
        } else if dto.type == "notification.invited" {
            let value = try container.decode(NotificationInvitedEventModel.self)
            self = .typeNotificationInvitedEvent(value)
        } else if dto.type == "notification.mark_read" {
            let value = try container.decode(NotificationMarkReadEventModel.self)
            self = .typeNotificationMarkReadEvent(value)
        } else if dto.type == "notification.mark_unread" {
            let value = try container.decode(NotificationMarkUnreadEventModel.self)
            self = .typeNotificationMarkUnreadEvent(value)
        } else if dto.type == "notification.message_new" {
            let value = try container.decode(NotificationNewMessageEvent.self)
            self = .typeNotificationNewMessageEvent(value)
        } else if dto.type == "notification.mutes_updated" {
            let value = try container.decode(NotificationMutesUpdatedEventModel.self)
            self = .typeNotificationMutesUpdatedEvent(value)
        } else if dto.type == "notification.reminder_due" {
            let value = try container.decode(ReminderNotificationEvent.self)
            self = .typeReminderNotificationEvent(value)
        } else if dto.type == "notification.removed_from_channel" {
            let value = try container.decode(NotificationRemovedFromChannelEventModel.self)
            self = .typeNotificationRemovedFromChannelEvent(value)
        } else if dto.type == "notification.thread_message_new" {
            let value = try container.decode(NotificationThreadMessageNewEvent.self)
            self = .typeNotificationThreadMessageNewEvent(value)
        } else if dto.type == "poll.closed" {
            let value = try container.decode(PollClosedEventModel.self)
            self = .typePollClosedEvent(value)
        } else if dto.type == "poll.deleted" {
            let value = try container.decode(PollDeletedEventModel.self)
            self = .typePollDeletedEvent(value)
        } else if dto.type == "poll.updated" {
            let value = try container.decode(PollUpdatedEventModel.self)
            self = .typePollUpdatedEvent(value)
        } else if dto.type == "poll.vote_casted" {
            let value = try container.decode(PollVoteCastedEventModel.self)
            self = .typePollVoteCastedEvent(value)
        } else if dto.type == "poll.vote_changed" {
            let value = try container.decode(PollVoteChangedEventModel.self)
            self = .typePollVoteChangedEvent(value)
        } else if dto.type == "poll.vote_removed" {
            let value = try container.decode(PollVoteRemovedEventModel.self)
            self = .typePollVoteRemovedEvent(value)
        } else if dto.type == "reaction.deleted" {
            let value = try container.decode(ReactionDeletedEventModel.self)
            self = .typeReactionDeletedEvent(value)
        } else if dto.type == "reaction.new" {
            let value = try container.decode(ReactionNewEventModel.self)
            self = .typeReactionNewEvent(value)
        } else if dto.type == "reaction.updated" {
            let value = try container.decode(ReactionUpdatedEventModel.self)
            self = .typeReactionUpdatedEvent(value)
        } else if dto.type == "reminder.created" {
            let value = try container.decode(ReminderCreatedEvent.self)
            self = .typeReminderCreatedEvent(value)
        } else if dto.type == "reminder.deleted" {
            let value = try container.decode(ReminderDeletedEvent.self)
            self = .typeReminderDeletedEvent(value)
        } else if dto.type == "reminder.updated" {
            let value = try container.decode(ReminderUpdatedEvent.self)
            self = .typeReminderUpdatedEvent(value)
        } else if dto.type == "thread.updated" {
            let value = try container.decode(ThreadUpdatedEventModel.self)
            self = .typeThreadUpdatedEvent(value)
        } else if dto.type == "typing.start" {
            let value = try container.decode(TypingStartEvent.self)
            self = .typeTypingStartEvent(value)
        } else if dto.type == "typing.stop" {
            let value = try container.decode(TypingStopEvent.self)
            self = .typeTypingStopEvent(value)
        } else if dto.type == "user.banned" {
            let value = try container.decode(UserBannedEventModel.self)
            self = .typeUserBannedEvent(value)
        } else if dto.type == "user.deactivated" {
            let value = try container.decode(UserDeactivatedEvent.self)
            self = .typeUserDeactivatedEvent(value)
        } else if dto.type == "user.deleted" {
            let value = try container.decode(UserDeletedEvent.self)
            self = .typeUserDeletedEvent(value)
        } else if dto.type == "user.messages.deleted" {
            let value = try container.decode(UserMessagesDeletedEventModel.self)
            self = .typeUserMessagesDeletedEvent(value)
        } else if dto.type == "user.muted" {
            let value = try container.decode(UserMutedEvent.self)
            self = .typeUserMutedEvent(value)
        } else if dto.type == "user.presence.changed" {
            let value = try container.decode(UserPresenceChangedEventModel.self)
            self = .typeUserPresenceChangedEvent(value)
        } else if dto.type == "user.reactivated" {
            let value = try container.decode(UserReactivatedEvent.self)
            self = .typeUserReactivatedEvent(value)
        } else if dto.type == "user.unbanned" {
            let value = try container.decode(UserUnbannedEventModel.self)
            self = .typeUserUnbannedEvent(value)
        } else if dto.type == "user.updated" {
            let value = try container.decode(UserUpdatedEventModel.self)
            self = .typeUserUpdatedEvent(value)
        } else if dto.type == "user.watching.start" {
            let value = try container.decode(UserWatchingStartEvent.self)
            self = .typeUserWatchingStartEvent(value)
        } else if dto.type == "user.watching.stop" {
            let value = try container.decode(UserWatchingStopEvent.self)
            self = .typeUserWatchingStopEvent(value)
        } else if dto.type == "user_group.created" {
            let value = try container.decode(UserGroupCreatedEvent.self)
            self = .typeUserGroupCreatedEvent(value)
        } else if dto.type == "user_group.deleted" {
            let value = try container.decode(UserGroupDeletedEvent.self)
            self = .typeUserGroupDeletedEvent(value)
        } else if dto.type == "user_group.member_added" {
            let value = try container.decode(UserGroupMemberAddedEvent.self)
            self = .typeUserGroupMemberAddedEvent(value)
        } else if dto.type == "user_group.member_removed" {
            let value = try container.decode(UserGroupMemberRemovedEvent.self)
            self = .typeUserGroupMemberRemovedEvent(value)
        } else if dto.type == "user_group.updated" {
            let value = try container.decode(UserGroupUpdatedEvent.self)
            self = .typeUserGroupUpdatedEvent(value)
        } else {
            throw DecodingError.typeMismatch(Self.Type.self, .init(codingPath: decoder.codingPath, debugDescription: "Unable to decode instance of WSClientEvent"))
        }
    }
}
