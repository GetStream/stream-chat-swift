//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Why sending a scheduled message failed.
final class ScheduledMessageFailureReason: RawRepresentable, Decodable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let banned = ScheduledMessageFailureReason(rawValue: "banned")
    static let channelDeleted = ScheduledMessageFailureReason(rawValue: "channel_deleted")
    static let channelFrozen = ScheduledMessageFailureReason(rawValue: "channel_frozen")
    static let expired = ScheduledMessageFailureReason(rawValue: "expired")
    static let hookRejected = ScheduledMessageFailureReason(rawValue: "hook_rejected")
    static let internalError = ScheduledMessageFailureReason(rawValue: "internal_error")
    static let invalidMessage = ScheduledMessageFailureReason(rawValue: "invalid_message")
    static let moderationBlocked = ScheduledMessageFailureReason(rawValue: "moderation_blocked")
    static let noPermission = ScheduledMessageFailureReason(rawValue: "no_permission")
    static let pendingNotSupported = ScheduledMessageFailureReason(rawValue: "pending_not_supported")
    static let userDeleted = ScheduledMessageFailureReason(rawValue: "user_deleted")
}
