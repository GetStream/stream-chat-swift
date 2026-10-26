//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Where a scheduled message is, from the local device until the server sends it.
///
/// The latest local changes win while they are not on the server yet, so an edit waiting to be sent shows as
/// `preparingToSchedule` even when the server already has the message.
public struct ScheduledMessageStatus: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    /// The latest changes are not on the server yet: the attachments are uploading, the device is offline,
    /// or the changes are being sent to schedule, edit or reschedule the message.
    public static let preparingToSchedule: Self = "preparing_to_schedule"

    /// The server has the latest changes and sends the message at `scheduledAt`.
    public static let scheduled: Self = "scheduled"

    /// The server started sending the message to the channel, at its scheduled date or after a send now,
    /// including while it retries a failed attempt.
    ///
    /// This happens on the server, not on the device: changes the device has not sent yet are `preparingToSchedule`.
    /// The message can no longer be edited, rescheduled or deleted, and it leaves the list once it is sent.
    public static let sending: Self = "sending"

    /// The message could not be scheduled or sent. See ``ScheduledMessage/failure``.
    public static let failed: Self = "failed"
}

extension ScheduledMessageStatus {
    init(localState: LocalMessageState?, serverStatus: String) {
        switch localState {
        case .pendingSend, .pendingSync, .sending, .syncing:
            self = .preparingToSchedule
        case .sendingFailed, .syncingFailed:
            self = .failed
        default:
            switch ScheduledMessageServerStatus(rawValue: serverStatus) {
            case .sending:
                self = .sending
            case .failed:
                self = .failed
            default:
                self = .scheduled
            }
        }
    }
}
