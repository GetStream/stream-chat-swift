//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Where a scheduled message is, from the local device until the server publishes it.
///
/// The latest local changes win while they are not on the server yet, so an edit waiting to be sent shows as
/// `waitingToSchedule` even when the server already has the message.
public struct ScheduledMessageStatus: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    /// The changes are saved on the device and wait to be sent to the server, for example until the attachments
    /// are uploaded or the device is online.
    public static let waitingToSchedule: Self = "waiting_to_schedule"

    /// The changes are being sent to the server, to schedule, edit or reschedule the message.
    public static let scheduling: Self = "scheduling"

    /// The server has the latest changes and publishes the message at `scheduledAt`.
    public static let scheduled: Self = "scheduled"

    /// The server is publishing the message. It can no longer be edited, rescheduled or deleted.
    public static let publishing: Self = "publishing"

    /// The message could not be scheduled or published. See `ScheduledMessage.error`.
    public static let failed: Self = "failed"
}

/// The status of a scheduled message on the server.
enum ScheduledMessageServerStatus: String {
    case scheduled
    case sending
    case failed
}

extension ScheduledMessageStatus {
    init(localState: LocalMessageState?, serverStatus: String) {
        switch localState {
        case .pendingSend, .pendingSync:
            self = .waitingToSchedule
        case .sending, .syncing:
            self = .scheduling
        case .sendingFailed, .syncingFailed:
            self = .failed
        default:
            switch ScheduledMessageServerStatus(rawValue: serverStatus) {
            case .sending:
                self = .publishing
            case .failed:
                self = .failed
            case .scheduled, nil:
                self = .scheduled
            }
        }
    }
}
