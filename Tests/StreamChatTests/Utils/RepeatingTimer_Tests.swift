//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class RepeatingTimer_Tests: XCTestCase {
    func test_state_isThreadSafe() {
        DispatchQueue.concurrentPerform(iterations: 10000) { _ in
            let repeatingTimer: RepeatingTimerControl? = DefaultTimer.scheduleRepeating(
                timeInterval: 0.4,
                queue: .main,
                onFire: {}
            )
            repeatingTimer?.resume()
            repeatingTimer?.suspend()
        }
    }

    func test_deinit_whenResumed_doesNotCrash() {
        var repeatingTimer: RepeatingTimerControl? = DefaultTimer.scheduleRepeating(
            timeInterval: 0.4,
            queue: .main,
            onFire: {}
        )
        repeatingTimer?.resume()
        repeatingTimer = nil
    }
    
    func test_deinit_whenSuspended_doesNotCrash() {
        var repeatingTimer: RepeatingTimerControl? = DefaultTimer.scheduleRepeating(
            timeInterval: 0.4,
            queue: .main,
            onFire: {}
        )
        repeatingTimer?.suspend()
        repeatingTimer = nil
    }
}
