//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelCapability: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let banChannelMembers = Self(rawValue: "ban-channel-members")
    public static let castPollVote = Self(rawValue: "cast-poll-vote")
    public static let connectEvents = Self(rawValue: "connect-events")
    public static let createAttachment = Self(rawValue: "create-attachment")
    public static let createMention = Self(rawValue: "create-mention")
    public static let deleteAnyMessage = Self(rawValue: "delete-any-message")
    public static let deleteChannel = Self(rawValue: "delete-channel")
    public static let deleteOwnMessage = Self(rawValue: "delete-own-message")
    public static let deliveryEvents = Self(rawValue: "delivery-events")
    public static let flagMessage = Self(rawValue: "flag-message")
    public static let freezeChannel = Self(rawValue: "freeze-channel")
    public static let joinChannel = Self(rawValue: "join-channel")
    public static let leaveChannel = Self(rawValue: "leave-channel")
    public static let muteChannel = Self(rawValue: "mute-channel")
    public static let notifyChannel = Self(rawValue: "notify-channel")
    public static let notifyGroup = Self(rawValue: "notify-group")
    public static let notifyHere = Self(rawValue: "notify-here")
    public static let notifyRole = Self(rawValue: "notify-role")
    public static let pinMessage = Self(rawValue: "pin-message")
    public static let queryPollVotes = Self(rawValue: "query-poll-votes")
    public static let quoteMessage = Self(rawValue: "quote-message")
    public static let readEvents = Self(rawValue: "read-events")
    public static let searchMessages = Self(rawValue: "search-messages")
    public static let sendCustomEvents = Self(rawValue: "send-custom-events")
    public static let sendLinks = Self(rawValue: "send-links")
    public static let sendMessage = Self(rawValue: "send-message")
    public static let sendPoll = Self(rawValue: "send-poll")
    public static let sendReaction = Self(rawValue: "send-reaction")
    public static let sendReply = Self(rawValue: "send-reply")
    public static let sendRestrictedVisibilityMessage = Self(rawValue: "send-restricted-visibility-message")
    public static let sendTypingEvents = Self(rawValue: "send-typing-events")
    public static let setChannelCooldown = Self(rawValue: "set-channel-cooldown")
    public static let shareLocation = Self(rawValue: "share-location")
    public static let skipSlowMode = Self(rawValue: "skip-slow-mode")
    public static let slowMode = Self(rawValue: "slow-mode")
    public static let typingEvents = Self(rawValue: "typing-events")
    public static let updateAnyMessage = Self(rawValue: "update-any-message")
    public static let updateChannel = Self(rawValue: "update-channel")
    public static let updateChannelMembers = Self(rawValue: "update-channel-members")
    public static let updateOwnMessage = Self(rawValue: "update-own-message")
    public static let updateThread = Self(rawValue: "update-thread")
    public static let uploadFile = Self(rawValue: "upload-file")
}
