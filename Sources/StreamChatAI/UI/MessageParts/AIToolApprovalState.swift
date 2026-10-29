//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Where the person's answer to a question is.
public struct AIToolApprovalState: Equatable, Sendable {
    /// The answer is on its way, or arrived and the call's step hasn't changed yet.
    public var isSending = false
    /// The answer couldn't be sent, and the person can answer again.
    public var failed = false

    public init(isSending: Bool = false, failed: Bool = false) {
        self.isSending = isSending
        self.failed = failed
    }
}
