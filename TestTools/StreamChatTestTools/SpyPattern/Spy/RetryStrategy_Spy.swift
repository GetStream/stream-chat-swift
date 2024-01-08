//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// Mock implementation of `RetryStrategy`.
final class RetryStrategy_Spy: RetryStrategy, Spy {
    enum Signature {
        static let nextRetryDelay = "nextRetryDelay()"
        static let resetConsecutiveFailures = "resetConsecutiveFailures()"
    }

    var recordedFunctions: [String] = []
    var consecutiveFailuresCount: Int = 0

    lazy var mock_incrementConsecutiveFailures = MockFunc.mock(for: incrementConsecutiveFailures)

    func incrementConsecutiveFailures() {
        record()
        mock_incrementConsecutiveFailures.call(with: ())
    }

    lazy var mock_resetConsecutiveFailures = MockFunc.mock(for: resetConsecutiveFailures)

    func resetConsecutiveFailures() {
        record()
        mock_resetConsecutiveFailures.call(with: ())
    }

    lazy var mock_nextRetryDelay = MockFunc.mock(for: nextRetryDelay)

    func nextRetryDelay() -> TimeInterval {
        record()
        return mock_nextRetryDelay.callAndReturn(())
    }
}
