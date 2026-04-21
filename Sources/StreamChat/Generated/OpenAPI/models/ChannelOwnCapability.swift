//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum ChannelOwnCapability: String, Sendable, Codable, CaseIterable {
    case banChannelMembers = "ban-channel-members"
    case castPollVote = "cast-poll-vote"
    case connectEvents = "connect-events"
    case createAttachment = "create-attachment"
    case deleteAnyMessage = "delete-any-message"
    case deleteChannel = "delete-channel"
    case deleteOwnMessage = "delete-own-message"
    case deliveryEvents = "delivery-events"
    case flagMessage = "flag-message"
    case freezeChannel = "freeze-channel"
    case joinChannel = "join-channel"
    case leaveChannel = "leave-channel"
    case muteChannel = "mute-channel"
    case pinMessage = "pin-message"
    case queryPollVotes = "query-poll-votes"
    case quoteMessage = "quote-message"
    case readEvents = "read-events"
    case searchMessages = "search-messages"
    case sendCustomEvents = "send-custom-events"
    case sendLinks = "send-links"
    case sendMessage = "send-message"
    case sendPoll = "send-poll"
    case sendReaction = "send-reaction"
    case sendReply = "send-reply"
    case sendRestrictedVisibilityMessage = "send-restricted-visibility-message"
    case sendTypingEvents = "send-typing-events"
    case setChannelCooldown = "set-channel-cooldown"
    case shareLocation = "share-location"
    case skipSlowMode = "skip-slow-mode"
    case slowMode = "slow-mode"
    case typingEvents = "typing-events"
    case updateAnyMessage = "update-any-message"
    case updateChannel = "update-channel"
    case updateChannelMembers = "update-channel-members"
    case updateOwnMessage = "update-own-message"
    case updateThread = "update-thread"
    case uploadFile = "upload-file"
    case unknown = "_unknown"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let decodedValue = try? container.decode(String.self),
           let value = ChannelOwnCapability(rawValue: decodedValue) {
            self = value
        } else {
            self = .unknown
        }
    }
}
