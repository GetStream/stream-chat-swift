//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// A formatter that converts the failure of a scheduled message to textual representation.
public protocol ScheduledMessageFailureFormatter {
    /// Formats why a scheduled message failed, for example "This channel is frozen.".
    /// - Parameter failure: The failure of the scheduled message, or `nil` when the failed message has none.
    func format(_ failure: ScheduledMessageFailure?) -> String
}

/// The default scheduled message failure formatter.
///
/// A failure without its own text is formatted as "Something went wrong. Try again".
open class DefaultScheduledMessageFailureFormatter: ScheduledMessageFailureFormatter {
    /// Creates the formatter.
    public init() {}

    open func format(_ failure: ScheduledMessageFailure?) -> String {
        switch failure {
        case let .localDeviceFailedScheduling(failure):
            return failure.reason == .attachmentUploadFailed
                ? L10n.ScheduledMessage.Failure.attachmentUploadFailed
                : L10n.ScheduledMessage.Failure.requestFailed
        case let .serverFailedPublishing(failure):
            return format(failure.reason)
        case let .serverRejectedScheduling(rejection):
            return format(rejection.reason)
        case nil:
            return L10n.ScheduledMessage.Failure.generic
        }
    }

    private func format(_ reason: ScheduledMessageFailureReason?) -> String {
        switch reason {
        case .banned:
            return L10n.ScheduledMessage.Failure.banned
        case .channelDeleted:
            return L10n.ScheduledMessage.Failure.channelDeleted
        case .channelFrozen:
            return L10n.ScheduledMessage.Failure.channelFrozen
        case .expired:
            return L10n.ScheduledMessage.Failure.expired
        case .hookRejected:
            return L10n.ScheduledMessage.Failure.hookRejected
        case .invalidMessage:
            return L10n.ScheduledMessage.Failure.invalidMessage
        case .moderationBlocked:
            return L10n.ScheduledMessage.Failure.moderationBlocked
        case .noPermission:
            return L10n.ScheduledMessage.Failure.noPermission
        case .pendingNotSupported:
            return L10n.ScheduledMessage.Failure.pendingNotSupported
        default:
            return L10n.ScheduledMessage.Failure.generic
        }
    }

    private func format(_ reason: ScheduledMessageFailure.ServerRejection.Reason?) -> String {
        switch reason {
        case .scheduledAtTooFar:
            return L10n.ScheduledMessage.Failure.tooFar
        case .scheduledAtTooSoon:
            return L10n.ScheduledMessage.Failure.tooSoon
        case .scheduledLimitChannel:
            return L10n.ScheduledMessage.Failure.channelLimit
        case .scheduledLimitUser:
            return L10n.ScheduledMessage.Failure.userLimit
        default:
            return L10n.ScheduledMessage.Failure.generic
        }
    }
}
