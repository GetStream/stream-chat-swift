//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The state of the local changes of a scheduled message that are not on the server yet.
///
/// A scheduled message is saved locally first, then sent to the server once its attachments are uploaded.
public struct ScheduledMessageSyncState: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    /// The changes wait to be sent, until the attachments are uploaded or the device is online.
    public static let pending: Self = "pending"

    /// The changes are being sent to the server.
    public static let syncing: Self = "syncing"

    /// The server rejected the changes, see `ScheduledMessage.syncError`, or an attachment could not be uploaded.
    public static let failed: Self = "failed"
}

extension ScheduledMessageSyncState {
    init?(_ localState: LocalMessageState?) {
        switch localState {
        case .pendingSend, .pendingSync:
            self = .pending
        case .sending, .syncing:
            self = .syncing
        case .sendingFailed, .syncingFailed:
            self = .failed
        default:
            return nil
        }
    }
}
