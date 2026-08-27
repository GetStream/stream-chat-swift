//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class ChannelCapability: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let banChannelMembers = ChannelCapability(rawValue: "ban-channel-members")
    public static let castPollVote = ChannelCapability(rawValue: "cast-poll-vote")
    public static let connectEvents = ChannelCapability(rawValue: "connect-events")
    public static let createAttachment = ChannelCapability(rawValue: "create-attachment")
    public static let createMention = ChannelCapability(rawValue: "create-mention")
    public static let deleteAnyMessage = ChannelCapability(rawValue: "delete-any-message")
    public static let deleteChannel = ChannelCapability(rawValue: "delete-channel")
    public static let deleteOwnMessage = ChannelCapability(rawValue: "delete-own-message")
    public static let deliveryEvents = ChannelCapability(rawValue: "delivery-events")
    public static let flagMessage = ChannelCapability(rawValue: "flag-message")
    public static let freezeChannel = ChannelCapability(rawValue: "freeze-channel")
    public static let joinChannel = ChannelCapability(rawValue: "join-channel")
    public static let leaveChannel = ChannelCapability(rawValue: "leave-channel")
    public static let muteChannel = ChannelCapability(rawValue: "mute-channel")
    public static let notifyChannel = ChannelCapability(rawValue: "notify-channel")
    public static let notifyGroup = ChannelCapability(rawValue: "notify-group")
    public static let notifyHere = ChannelCapability(rawValue: "notify-here")
    public static let notifyRole = ChannelCapability(rawValue: "notify-role")
    public static let pinMessage = ChannelCapability(rawValue: "pin-message")
    public static let queryPollVotes = ChannelCapability(rawValue: "query-poll-votes")
    public static let quoteMessage = ChannelCapability(rawValue: "quote-message")
    public static let readEvents = ChannelCapability(rawValue: "read-events")
    public static let searchMessages = ChannelCapability(rawValue: "search-messages")
    public static let sendCustomEvents = ChannelCapability(rawValue: "send-custom-events")
    public static let sendLinks = ChannelCapability(rawValue: "send-links")
    public static let sendMessage = ChannelCapability(rawValue: "send-message")
    public static let sendPoll = ChannelCapability(rawValue: "send-poll")
    public static let sendReaction = ChannelCapability(rawValue: "send-reaction")
    public static let sendReply = ChannelCapability(rawValue: "send-reply")
    public static let sendRestrictedVisibilityMessage = ChannelCapability(rawValue: "send-restricted-visibility-message")
    public static let sendTypingEvents = ChannelCapability(rawValue: "send-typing-events")
    public static let setChannelCooldown = ChannelCapability(rawValue: "set-channel-cooldown")
    public static let shareLocation = ChannelCapability(rawValue: "share-location")
    public static let skipSlowMode = ChannelCapability(rawValue: "skip-slow-mode")
    public static let slowMode = ChannelCapability(rawValue: "slow-mode")
    public static let typingEvents = ChannelCapability(rawValue: "typing-events")
    public static let updateAnyMessage = ChannelCapability(rawValue: "update-any-message")
    public static let updateChannel = ChannelCapability(rawValue: "update-channel")
    public static let updateChannelMembers = ChannelCapability(rawValue: "update-channel-members")
    public static let updateOwnMessage = ChannelCapability(rawValue: "update-own-message")
    public static let updateThread = ChannelCapability(rawValue: "update-thread")
    public static let uploadFile = ChannelCapability(rawValue: "upload-file")
}
