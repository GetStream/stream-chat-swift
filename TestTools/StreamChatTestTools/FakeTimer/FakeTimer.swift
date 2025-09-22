//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

class FakeTimer: StreamChat.Timer {
    static let mockTimer = AllocatedUnfairLock<TimerControl?>(nil)
    static let mockRepeatingTimer = AllocatedUnfairLock<RepeatingTimerControl?>(nil)

    static func schedule(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) -> StreamChat.TimerControl {
        mockTimer.value!
    }

    static func scheduleRepeating(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) -> StreamChat.RepeatingTimerControl {
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
