//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An action that can be performed in a channel.
public final class ChannelCapability: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Ability to ban channel members.
    public static let banChannelMembers = ChannelCapability(rawValue: "ban-channel-members")
    /// Ability to cast a poll vote.
    public static let castPollVote = ChannelCapability(rawValue: "cast-poll-vote")
    /// Ability to receive connect events.
    public static let connectEvents = ChannelCapability(rawValue: "connect-events")
    /// Ability to attach files to messages.
    public static let createAttachment = ChannelCapability(rawValue: "create-attachment")
    /// Ability to mention users in messages.
    public static let createMention = ChannelCapability(rawValue: "create-mention")
    /// Ability to delete any message from the channel.
    public static let deleteAnyMessage = ChannelCapability(rawValue: "delete-any-message")
    /// Ability to delete the channel.
    public static let deleteChannel = ChannelCapability(rawValue: "delete-channel")
    /// Ability to delete own messages from the channel.
    public static let deleteOwnMessage = ChannelCapability(rawValue: "delete-own-message")
    /// Ability to receive delivery events.
    public static let deliveryEvents = ChannelCapability(rawValue: "delivery-events")
    /// Ability to flag a message.
    public static let flagMessage = ChannelCapability(rawValue: "flag-message")
    /// Ability to freeze or unfreeze the channel.
    public static let freezeChannel = ChannelCapability(rawValue: "freeze-channel")
    /// Ability to join channel (add own membership).
    public static let joinChannel = ChannelCapability(rawValue: "join-channel")
    /// Ability to leave the channel (remove own membership).
    public static let leaveChannel = ChannelCapability(rawValue: "leave-channel")
    /// Ability to mute the channel.
    public static let muteChannel = ChannelCapability(rawValue: "mute-channel")
    /// Ability to notify all channel members using @channel mention.
    public static let notifyChannel = ChannelCapability(rawValue: "notify-channel")
    /// Ability to notify channel members using user group mentions.
    public static let notifyGroup = ChannelCapability(rawValue: "notify-group")
    /// Ability to notify online channel members using @here mention.
    public static let notifyHere = ChannelCapability(rawValue: "notify-here")
    /// Ability to notify channel members using role mentions.
    public static let notifyRole = ChannelCapability(rawValue: "notify-role")
    /// Ability to pin a message.
    public static let pinMessage = ChannelCapability(rawValue: "pin-message")
    /// Ability to query poll votes.
    public static let queryPollVotes = ChannelCapability(rawValue: "query-poll-votes")
    /// Ability to quote a message.
    public static let quoteMessage = ChannelCapability(rawValue: "quote-message")
    /// Ability to receive read events.
    public static let readEvents = ChannelCapability(rawValue: "read-events")
    /// Ability to use message search.
    public static let searchMessages = ChannelCapability(rawValue: "search-messages")
    /// Ability to send custom events.
    public static let sendCustomEvents = ChannelCapability(rawValue: "send-custom-events")
    /// Ability to attach links to messages.
    public static let sendLinks = ChannelCapability(rawValue: "send-links")
    /// Ability to send a message.
    public static let sendMessage = ChannelCapability(rawValue: "send-message")
    /// Ability to send a poll.
    public static let sendPoll = ChannelCapability(rawValue: "send-poll")
    /// Ability to send reactions.
    public static let sendReaction = ChannelCapability(rawValue: "send-reaction")
    /// Ability to thread reply to a message.
    public static let sendReply = ChannelCapability(rawValue: "send-reply")
    /// Ability to send a message with restricted visibility.
    public static let sendRestrictedVisibilityMessage = ChannelCapability(rawValue: "send-restricted-visibility-message")
    /// Ability to send and receive typing events.
    public static let sendTypingEvents = ChannelCapability(rawValue: "send-typing-events")
    /// Ability to enable or disable slow mode.
    public static let setChannelCooldown = ChannelCapability(rawValue: "set-channel-cooldown")
    /// Ability to share location.
    public static let shareLocation = ChannelCapability(rawValue: "share-location")
    /// Ability to skip the slow mode when it's active.
    public static let skipSlowMode = ChannelCapability(rawValue: "skip-slow-mode")
    /// Indicates that channel slow mode is active.
    public static let slowMode = ChannelCapability(rawValue: "slow-mode")
    /// Ability to send and receive typing events.
    public static let typingEvents = ChannelCapability(rawValue: "typing-events")
    /// Ability to update any message in the channel.
    public static let updateAnyMessage = ChannelCapability(rawValue: "update-any-message")
    /// Ability to update channel data.
    public static let updateChannel = ChannelCapability(rawValue: "update-channel")
    /// Ability to update channel members.
    public static let updateChannelMembers = ChannelCapability(rawValue: "update-channel-members")
    /// Ability to update own messages in the channel.
    public static let updateOwnMessage = ChannelCapability(rawValue: "update-own-message")
    /// Ability to update thread data.
    public static let updateThread = ChannelCapability(rawValue: "update-thread")
    /// Ability to upload message attachments.
    public static let uploadFile = ChannelCapability(rawValue: "upload-file")
}
