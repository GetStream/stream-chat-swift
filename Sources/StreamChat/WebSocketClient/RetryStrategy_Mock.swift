//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import StreamChatTestTools

/// Mock implementation of `RetryStrategy`.
final class MockRetryStrategy: RetryStrategy {
    var consecutiveFailuresCount: Int = 0
    
    lazy var mock_incrementConsecutiveFailures = MockFunc.mock(for: incrementConsecutiveFailures)
    
    func incrementConsecutiveFailures() {
        mock_incrementConsecutiveFailures.call(with: ())
    }
    
    lazy var mock_resetConsecutiveFailures = MockFunc.mock(for: resetConsecutiveFailures)
    
    func resetConsecutiveFailures() {
        mock_resetConsecutiveFailures.call(with: ())
    }
    
    lazy var mock_nextRetryDelay = MockFunc.mock(for: nextRetryDelay)
    
    func nextRetryDelay() -> TimeInterval {
        mock_nextRetryDelay.callAndReturn(())
    }
}
