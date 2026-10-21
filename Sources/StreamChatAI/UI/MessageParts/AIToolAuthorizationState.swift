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
    /// The sign-in couldn't be opened, or the "not now" couldn't be sent, and the person can
    /// try again.
    public var failed = false

    /// Whether an answer is under way, so the buttons wait.
    public var isBusy: Bool { isConnecting || isDeclining }

    public init(isConnecting: Bool = false, isDeclining: Bool = false, failed: Bool = false) {
        self.isConnecting = isConnecting
        self.isDeclining = isDeclining
        self.failed = failed
    }
}
