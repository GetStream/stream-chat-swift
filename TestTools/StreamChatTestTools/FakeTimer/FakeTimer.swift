//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import class StreamCore.AllocatedUnfairLock
import protocol StreamCore.RepeatingTimerControl
import protocol StreamCore.TimerControl
import protocol StreamCore.TimerScheduling

class FakeTimer: TimerScheduling {
    static let mockTimer = AllocatedUnfairLock<TimerControl?>(nil)
    static let mockRepeatingTimer = AllocatedUnfairLock<RepeatingTimerControl?>(nil)

    static func schedule(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) -> TimerControl {
        mockTimer.value!
    }

    static func scheduleRepeating(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) -> RepeatingTimerControl {
        mockRepeatingTimer.value!
    }
}

class MockTimer: TimerControl, @unchecked Sendable {
    var cancelCallCount = 0
    func cancel() {
        cancelCallCount += 1
    }
}

class MockRepeatingTimer: RepeatingTimerControl, @unchecked Sendable {
    var resumeCallCount = 0
    var suspendCallCount = 0

    func resume() {
        resumeCallCount += 1
    }

    func suspend() {
        suspendCallCount += 1
    }
}
