//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The reason a scheduled message could not be sent.
public struct ScheduledMessageFailureReason: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    /// The current user is banned from the channel.
    public static let banned: Self = "banned"

    /// The current user is no longer allowed to send messages to the channel.
    public static let noPermission: Self = "no_permission"

    /// The channel is frozen.
    public static let channelFrozen: Self = "channel_frozen"

    /// The channel was deleted.
    public static let channelDeleted: Self = "channel_deleted"

    /// The current user was deleted.
    public static let userDeleted: Self = "user_deleted"

    /// Moderation blocked the message.
    public static let moderationBlocked: Self = "moderation_blocked"

    /// A before-message-send hook rejected the message.
    public static let hookRejected: Self = "hook_rejected"

    /// The server could not send the message within an hour of `scheduledAt`.
    public static let expired: Self = "expired"

    /// The message no longer meets the app's limits, for example its length.
    public static let invalidMessage: Self = "invalid_message"

    /// The server failed to send the message.
    public static let internalError: Self = "internal_error"
}
