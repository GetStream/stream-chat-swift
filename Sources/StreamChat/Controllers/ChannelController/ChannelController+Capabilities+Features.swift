//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - Channel current user capabilities

public extension ChatChannelController {
    /// Can the current user ban members from this channel.
    var canBanChannelMembers: Bool {
        channel?.ownCapabilities.contains(.banChannelMembers) == true
    }

    /// Can the current user receive connect events from this channel.
    var canReceiveConnectEvents: Bool {
        channel?.ownCapabilities.contains(.connectEvents) == true
    }

    /// Can the current user delete any message from this channel.
    var canDeleteAnyMessage: Bool {
        channel?.ownCapabilities.contains(.deleteAnyMessage) == true
    }

    /// Can the current user delete the channel.
    var canDeleteChannel: Bool {
        channel?.ownCapabilities.contains(.deleteChannel) == true
    }

    /// Can the current user delete own messages from the channel.
    var canDeleteOwnMessage: Bool {
        channel?.ownCapabilities.contains(.deleteOwnMessage) == true
    }

    /// Can the current user flag a message in this channel.
    var canFlagMessage: Bool {
        channel?.ownCapabilities.contains(.flagMessage) == true
    }

    /// Can the current user freeze or unfreeze the channel.
    var canFreezeChannel: Bool {
        channel?.ownCapabilities.contains(.freezeChannel) == true
    }

    /// Can the current user leave the channel (remove own membership).
    var canLeaveChannel: Bool {
        channel?.ownCapabilities.contains(.leaveChannel) == true
    }

    /// Can the current user join the channel (add own membership).
    var canJoinChannel: Bool {
        channel?.ownCapabilities.contains(.joinChannel) == true
    }

    /// Can the current user mute the channel.
    var canMuteChannel: Bool {
        channel?.ownCapabilities.contains(.muteChannel) == true
    }

    /// Can the current user pin a message in this channel.
    var canPinMessage: Bool {
        channel?.ownCapabilities.contains(.pinMessage) == true
    }

    /// Can the current user quote a message in this channel.
    var canQuoteMessage: Bool {
        channel?.ownCapabilities.contains(.quoteMessage) == true
    }

    /// Can the current user receive read events from this channel.
    var canReceiveReadEvents: Bool {
        channel?.ownCapabilities.contains(.readEvents) == true
    }

    /// Can the current user use message search in this channel.
    var canSearchMessages: Bool {
        channel?.ownCapabilities.contains(.searchMessages) == true
    }

    /// Can the current user send custom events in this channel.
    var canSendCustomEvents: Bool {
        channel?.ownCapabilities.contains(.sendCustomEvents) == true
    }

    /// Can the current user attach links to messages in this channel.
    var canSendLinks: Bool {
        channel?.ownCapabilities.contains(.sendLinks) == true
    }

    /// Can the current user send a message in this channel.
    var canSendMessage: Bool {
        channel?.ownCapabilities.contains(.sendMessage) == true
    }

    /// Can the current user send reactions in this channel.
    var canSendReaction: Bool {
        channel?.ownCapabilities.contains(.sendReaction) == true
    }

    /// Can the current user thread reply to a message in this channel.
    var canSendReply: Bool {
        channel?.ownCapabilities.contains(.sendReply) == true
    }

    /// Can the current user enable or disable slow mode in this channel.
    var canSetChannelCooldown: Bool {
        channel?.ownCapabilities.contains(.setChannelCooldown) == true
    }

    /// Can the current user send and receive typing events in this channel.
    var canSendTypingEvents: Bool {
        channel?.ownCapabilities.contains(.sendTypingEvents) == true
    }

    /// Can the current user update any message in this channel.
    var canUpdateAnyMessage: Bool {
        channel?.ownCapabilities.contains(.updateAnyMessage) == true
    }

    /// Can the current user update channel data.
    var canUpdateChannel: Bool {
        channel?.ownCapabilities.contains(.updateChannel) == true
    }

    /// Can the current user update channel members.
    var canUpdateChannelMembers: Bool {
        channel?.ownCapabilities.contains(.updateChannelMembers) == true
    }

    /// Can the current user update own messages in this channel.
    var canUpdateOwnMessage: Bool {
        channel?.ownCapabilities.contains(.updateOwnMessage) == true
    }

    /// Can the current user upload message attachments in this channel.
    var canUploadFile: Bool {
        channel?.ownCapabilities.contains(.uploadFile) == true
    }

    /// Can the current user join a call in this channel.
    var canJoinCall: Bool {
        channel?.ownCapabilities.contains(.joinCall) == true
    }

    /// Can the current user create a call in this channel.
    var canCreateCall: Bool {
        channel?.ownCapabilities.contains(.createCall) == true
    }
}

// MARK: - Channel features

public extension ChatChannelController {
    /// Indicates whether the channel has typing events enabled.
    var areTypingEventsEnabled: Bool {
        channel?.config.typingEventsEnabled == true
    }

    /// Indicates whether the channel has reactions enabled.
    var areReactionsEnabled: Bool {
        channel?.config.reactionsEnabled == true
    }

    /// Indicates whether the channel has replies enabled.
    var areRepliesEnabled: Bool {
        channel?.config.repliesEnabled == true
    }

    /// Indicates whether the channel has quotes enabled.
    var areQuotesEnabled: Bool {
        channel?.config.quotesEnabled == true
    }

    /// Indicates whether the channel has read events enabled.
    var areReadEventsEnabled: Bool {
        channel?.config.readEventsEnabled == true
    }

    /// Indicates whether the channel supports uploading files/images.
    var areUploadsEnabled: Bool {
        channel?.config.uploadsEnabled == true
    }

    /// Is slow mode active in this channel.
    var isSlowMode: Bool {
        channel?.ownCapabilities.contains(.slowMode) == true
    }
}
