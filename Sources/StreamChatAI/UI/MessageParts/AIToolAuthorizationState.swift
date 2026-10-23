//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Where the person's sign-in is.
public struct AIToolAuthorizationState: Equatable, Sendable {
    /// The sign-in is open, or done and the call's step hasn't changed yet.
    public var isConnecting = false
    /// Their "not now" is on its way, or arrived and the call's step hasn't changed yet.
    public var isDeclining = false
    /// The sign-in couldn't be opened, and the person can try again.
    public var connectFailed = false
    /// Their "not now" couldn't be sent, and the person can answer again.
    public var declineFailed = false

    /// Whether an answer is under way, so the buttons wait.
    public var isBusy: Bool { isConnecting || isDeclining }

    public init(
        isConnecting: Bool = false,
        isDeclining: Bool = false,
        connectFailed: Bool = false,
        declineFailed: Bool = false
    ) {
        self.isConnecting = isConnecting
        self.isDeclining = isDeclining
        self.connectFailed = connectFailed
        self.declineFailed = declineFailed
    }
}
