//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

internal class ChatEventMapping: Decodable {
    let type: String
}

public enum StreamChatWSEvent: Codable, Hashable {
    case typeCallAcceptedEvent(StreamChatCallAcceptedEvent)
    
    case typeBlockedUserEvent(StreamChatBlockedUserEvent)
    
    case typeCallCreatedEvent(StreamChatCallCreatedEvent)
    
    case typeCallDeletedEvent(StreamChatCallDeletedEvent)
    
    case typeCallEndedEvent(StreamChatCallEndedEvent)
    
    case typeCallHLSBroadcastingFailedEvent(StreamChatCallHLSBroadcastingFailedEvent)
    
    case typeCallHLSBroadcastingStartedEvent(StreamChatCallHLSBroadcastingStartedEvent)
    
    case typeCallHLSBroadcastingStoppedEvent(StreamChatCallHLSBroadcastingStoppedEvent)
    
    case typeCallLiveStartedEvent(StreamChatCallLiveStartedEvent)
    
    case typeCallMemberAddedEvent(StreamChatCallMemberAddedEvent)
    
    case typeCallMemberRemovedEvent(StreamChatCallMemberRemovedEvent)
    
    case typeCallMemberUpdatedEvent(StreamChatCallMemberUpdatedEvent)
    
    case typeCallMemberUpdatedPermissionEvent(StreamChatCallMemberUpdatedPermissionEvent)
    
    case typeCallNotificationEvent(StreamChatCallNotificationEvent)
    
    case typePermissionRequestEvent(StreamChatPermissionRequestEvent)
    
    case typeUpdatedCallPermissionsEvent(StreamChatUpdatedCallPermissionsEvent)
    
    case typeCallReactionEvent(StreamChatCallReactionEvent)
    
    case typeCallRecordingFailedEvent(StreamChatCallRecordingFailedEvent)
    
    case typeCallRecordingReadyEvent(StreamChatCallRecordingReadyEvent)
    
    case typeCallRecordingStartedEvent(StreamChatCallRecordingStartedEvent)
    
    case typeCallRecordingStoppedEvent(StreamChatCallRecordingStoppedEvent)
    
    case typeCallRejectedEvent(StreamChatCallRejectedEvent)
    
    case typeCallRingEvent(StreamChatCallRingEvent)
    
    case typeCallSessionEndedEvent(StreamChatCallSessionEndedEvent)
    
    case typeCallSessionParticipantJoinedEvent(StreamChatCallSessionParticipantJoinedEvent)
    
    case typeCallSessionParticipantLeftEvent(StreamChatCallSessionParticipantLeftEvent)
    
    case typeCallSessionStartedEvent(StreamChatCallSessionStartedEvent)
    
    case typeUnblockedUserEvent(StreamChatUnblockedUserEvent)
    
    case typeCallUpdatedEvent(StreamChatCallUpdatedEvent)
    
    case typeCallUserMuted(StreamChatCallUserMuted)
    
    case typeChannelCreatedEvent(StreamChatChannelCreatedEvent)
    
    case typeChannelDeletedEvent(StreamChatChannelDeletedEvent)
    
    case typeChannelFrozenEvent(StreamChatChannelFrozenEvent)
    
    case typeChannelHiddenEvent(StreamChatChannelHiddenEvent)
    
    case typeChannelKickedEvent(StreamChatChannelKickedEvent)
    
    case typeChannelTruncatedEvent(StreamChatChannelTruncatedEvent)
    
    case typeChannelUnFrozenEvent(StreamChatChannelUnFrozenEvent)
    
    case typeChannelUpdatedEvent(StreamChatChannelUpdatedEvent)
    
    case typeChannelVisibleEvent(StreamChatChannelVisibleEvent)
    
    case typeConnectionErrorEvent(StreamChatConnectionErrorEvent)
    
    case typeConnectedEvent(StreamChatConnectedEvent)
    
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
    
    case typeUserUpdatedEvent(StreamChatUserUpdatedEvent)
    
    case typeUserWatchingStartEvent(StreamChatUserWatchingStartEvent)
    
    case typeUserWatchingStopEvent(StreamChatUserWatchingStopEvent)
    
    public var type: String {
        switch self {
        case let .typeCallAcceptedEvent(value):
            return value.type
        case let .typeBlockedUserEvent(value):
            return value.type
        case let .typeCallCreatedEvent(value):
            return value.type
        case let .typeCallDeletedEvent(value):
            return value.type
        case let .typeCallEndedEvent(value):
            return value.type
        case let .typeCallHLSBroadcastingFailedEvent(value):
            return value.type
        case let .typeCallHLSBroadcastingStartedEvent(value):
            return value.type
        case let .typeCallHLSBroadcastingStoppedEvent(value):
            return value.type
        case let .typeCallLiveStartedEvent(value):
            return value.type
        case let .typeCallMemberAddedEvent(value):
            return value.type
        case let .typeCallMemberRemovedEvent(value):
            return value.type
        case let .typeCallMemberUpdatedEvent(value):
            return value.type
        case let .typeCallMemberUpdatedPermissionEvent(value):
            return value.type
        case let .typeCallNotificationEvent(value):
            return value.type
        case let .typePermissionRequestEvent(value):
            return value.type
        case let .typeUpdatedCallPermissionsEvent(value):
            return value.type
        case let .typeCallReactionEvent(value):
            return value.type
        case let .typeCallRecordingFailedEvent(value):
            return value.type
        case let .typeCallRecordingReadyEvent(value):
            return value.type
        case let .typeCallRecordingStartedEvent(value):
            return value.type
        case let .typeCallRecordingStoppedEvent(value):
            return value.type
        case let .typeCallRejectedEvent(value):
            return value.type
        case let .typeCallRingEvent(value):
            return value.type
        case let .typeCallSessionEndedEvent(value):
            return value.type
        case let .typeCallSessionParticipantJoinedEvent(value):
            return value.type
        case let .typeCallSessionParticipantLeftEvent(value):
            return value.type
        case let .typeCallSessionStartedEvent(value):
            return value.type
        case let .typeUnblockedUserEvent(value):
            return value.type
        case let .typeCallUpdatedEvent(value):
            return value.type
        case let .typeCallUserMuted(value):
            return value.type
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
        case let .typeConnectionErrorEvent(value):
            return value.type
        case let .typeConnectedEvent(value):
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
        case let .typeConnectionErrorEvent(value):
            return value
        case let .typeConnectedEvent(value):
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
        case let .typeReactionDeletedEvent(value):
            return value
        case let .typeReactionNewEvent(value):
            return value
        case let .typeReactionUpdatedEvent(value):
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
        default:
            return HealthCheckEvent(connectionId: "test")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .typeCallAcceptedEvent(value):
            try container.encode(value)
        case let .typeBlockedUserEvent(value):
            try container.encode(value)
        case let .typeCallCreatedEvent(value):
            try container.encode(value)
        case let .typeCallDeletedEvent(value):
            try container.encode(value)
        case let .typeCallEndedEvent(value):
            try container.encode(value)
        case let .typeCallHLSBroadcastingFailedEvent(value):
            try container.encode(value)
        case let .typeCallHLSBroadcastingStartedEvent(value):
            try container.encode(value)
        case let .typeCallHLSBroadcastingStoppedEvent(value):
            try container.encode(value)
        case let .typeCallLiveStartedEvent(value):
            try container.encode(value)
        case let .typeCallMemberAddedEvent(value):
            try container.encode(value)
        case let .typeCallMemberRemovedEvent(value):
            try container.encode(value)
        case let .typeCallMemberUpdatedEvent(value):
            try container.encode(value)
        case let .typeCallMemberUpdatedPermissionEvent(value):
            try container.encode(value)
        case let .typeCallNotificationEvent(value):
            try container.encode(value)
        case let .typePermissionRequestEvent(value):
            try container.encode(value)
        case let .typeUpdatedCallPermissionsEvent(value):
            try container.encode(value)
        case let .typeCallReactionEvent(value):
            try container.encode(value)
        case let .typeCallRecordingFailedEvent(value):
            try container.encode(value)
        case let .typeCallRecordingReadyEvent(value):
            try container.encode(value)
        case let .typeCallRecordingStartedEvent(value):
            try container.encode(value)
        case let .typeCallRecordingStoppedEvent(value):
            try container.encode(value)
        case let .typeCallRejectedEvent(value):
            try container.encode(value)
        case let .typeCallRingEvent(value):
            try container.encode(value)
        case let .typeCallSessionEndedEvent(value):
            try container.encode(value)
        case let .typeCallSessionParticipantJoinedEvent(value):
            try container.encode(value)
        case let .typeCallSessionParticipantLeftEvent(value):
            try container.encode(value)
        case let .typeCallSessionStartedEvent(value):
            try container.encode(value)
        case let .typeUnblockedUserEvent(value):
            try container.encode(value)
        case let .typeCallUpdatedEvent(value):
            try container.encode(value)
        case let .typeCallUserMuted(value):
            try container.encode(value)
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
        case let .typeConnectionErrorEvent(value):
            try container.encode(value)
        case let .typeConnectedEvent(value):
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
        if dto.type == "call.accepted" {
            let value = try container.decode(StreamChatCallAcceptedEvent.self)
            self = .typeCallAcceptedEvent(value)
        } else if dto.type == "call.blocked_user" {
            let value = try container.decode(StreamChatBlockedUserEvent.self)
            self = .typeBlockedUserEvent(value)
        } else if dto.type == "call.created" {
            let value = try container.decode(StreamChatCallCreatedEvent.self)
            self = .typeCallCreatedEvent(value)
        } else if dto.type == "call.deleted" {
            let value = try container.decode(StreamChatCallDeletedEvent.self)
            self = .typeCallDeletedEvent(value)
        } else if dto.type == "call.ended" {
            let value = try container.decode(StreamChatCallEndedEvent.self)
            self = .typeCallEndedEvent(value)
        } else if dto.type == "call.hls_broadcasting_failed" {
            let value = try container.decode(StreamChatCallHLSBroadcastingFailedEvent.self)
            self = .typeCallHLSBroadcastingFailedEvent(value)
        } else if dto.type == "call.hls_broadcasting_started" {
            let value = try container.decode(StreamChatCallHLSBroadcastingStartedEvent.self)
            self = .typeCallHLSBroadcastingStartedEvent(value)
        } else if dto.type == "call.hls_broadcasting_stopped" {
            let value = try container.decode(StreamChatCallHLSBroadcastingStoppedEvent.self)
            self = .typeCallHLSBroadcastingStoppedEvent(value)
        } else if dto.type == "call.live_started" {
            let value = try container.decode(StreamChatCallLiveStartedEvent.self)
            self = .typeCallLiveStartedEvent(value)
        } else if dto.type == "call.member_added" {
            let value = try container.decode(StreamChatCallMemberAddedEvent.self)
            self = .typeCallMemberAddedEvent(value)
        } else if dto.type == "call.member_removed" {
            let value = try container.decode(StreamChatCallMemberRemovedEvent.self)
            self = .typeCallMemberRemovedEvent(value)
        } else if dto.type == "call.member_updated" {
            let value = try container.decode(StreamChatCallMemberUpdatedEvent.self)
            self = .typeCallMemberUpdatedEvent(value)
        } else if dto.type == "call.member_updated_permission" {
            let value = try container.decode(StreamChatCallMemberUpdatedPermissionEvent.self)
            self = .typeCallMemberUpdatedPermissionEvent(value)
        } else if dto.type == "call.notification" {
            let value = try container.decode(StreamChatCallNotificationEvent.self)
            self = .typeCallNotificationEvent(value)
        } else if dto.type == "call.permission_request" {
            let value = try container.decode(StreamChatPermissionRequestEvent.self)
            self = .typePermissionRequestEvent(value)
        } else if dto.type == "call.permissions_updated" {
            let value = try container.decode(StreamChatUpdatedCallPermissionsEvent.self)
            self = .typeUpdatedCallPermissionsEvent(value)
        } else if dto.type == "call.reaction_new" {
            let value = try container.decode(StreamChatCallReactionEvent.self)
            self = .typeCallReactionEvent(value)
        } else if dto.type == "call.recording_failed" {
            let value = try container.decode(StreamChatCallRecordingFailedEvent.self)
            self = .typeCallRecordingFailedEvent(value)
        } else if dto.type == "call.recording_ready" {
            let value = try container.decode(StreamChatCallRecordingReadyEvent.self)
            self = .typeCallRecordingReadyEvent(value)
        } else if dto.type == "call.recording_started" {
            let value = try container.decode(StreamChatCallRecordingStartedEvent.self)
            self = .typeCallRecordingStartedEvent(value)
        } else if dto.type == "call.recording_stopped" {
            let value = try container.decode(StreamChatCallRecordingStoppedEvent.self)
            self = .typeCallRecordingStoppedEvent(value)
        } else if dto.type == "call.rejected" {
            let value = try container.decode(StreamChatCallRejectedEvent.self)
            self = .typeCallRejectedEvent(value)
        } else if dto.type == "call.ring" {
            let value = try container.decode(StreamChatCallRingEvent.self)
            self = .typeCallRingEvent(value)
        } else if dto.type == "call.session_ended" {
            let value = try container.decode(StreamChatCallSessionEndedEvent.self)
            self = .typeCallSessionEndedEvent(value)
        } else if dto.type == "call.session_participant_joined" {
            let value = try container.decode(StreamChatCallSessionParticipantJoinedEvent.self)
            self = .typeCallSessionParticipantJoinedEvent(value)
        } else if dto.type == "call.session_participant_left" {
            let value = try container.decode(StreamChatCallSessionParticipantLeftEvent.self)
            self = .typeCallSessionParticipantLeftEvent(value)
        } else if dto.type == "call.session_started" {
            let value = try container.decode(StreamChatCallSessionStartedEvent.self)
            self = .typeCallSessionStartedEvent(value)
        } else if dto.type == "call.unblocked_user" {
            let value = try container.decode(StreamChatUnblockedUserEvent.self)
            self = .typeUnblockedUserEvent(value)
        } else if dto.type == "call.updated" {
            let value = try container.decode(StreamChatCallUpdatedEvent.self)
            self = .typeCallUpdatedEvent(value)
        } else if dto.type == "call.user_muted" {
            let value = try container.decode(StreamChatCallUserMuted.self)
            self = .typeCallUserMuted(value)
        } else if dto.type == "channel.created" {
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
        } else if dto.type == "connection.error" {
            let value = try container.decode(StreamChatConnectionErrorEvent.self)
            self = .typeConnectionErrorEvent(value)
        } else if dto.type == "connection.ok" {
            let value = try container.decode(StreamChatConnectedEvent.self)
            self = .typeConnectedEvent(value)
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