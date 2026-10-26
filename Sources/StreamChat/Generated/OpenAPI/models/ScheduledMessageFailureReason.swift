//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Why sending a scheduled message failed.
public final class ScheduledMessageFailureReason: RawRepresentable, Decodable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let banned = ScheduledMessageFailureReason(rawValue: "banned")
    public static let channelDeleted = ScheduledMessageFailureReason(rawValue: "channel_deleted")
    public static let channelFrozen = ScheduledMessageFailureReason(rawValue: "channel_frozen")
    public static let expired = ScheduledMessageFailureReason(rawValue: "expired")
    public static let hookRejected = ScheduledMessageFailureReason(rawValue: "hook_rejected")
    public static let internalError = ScheduledMessageFailureReason(rawValue: "internal_error")
    public static let invalidMessage = ScheduledMessageFailureReason(rawValue: "invalid_message")
    public static let moderationBlocked = ScheduledMessageFailureReason(rawValue: "moderation_blocked")
    public static let noPermission = ScheduledMessageFailureReason(rawValue: "no_permission")
    public static let pendingNotSupported = ScheduledMessageFailureReason(rawValue: "pending_not_supported")
    public static let userDeleted = ScheduledMessageFailureReason(rawValue: "user_deleted")
}
