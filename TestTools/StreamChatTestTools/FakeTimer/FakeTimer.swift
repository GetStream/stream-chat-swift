//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

class FakeTimer: StreamChat.Timer {
    static var mockTimer: TimerControl?
    static var mockRepeatingTimer: RepeatingTimerControl?

    static func schedule(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) -> StreamChat.TimerControl {
        return mockTimer!
    }

    static func scheduleRepeating(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) -> StreamChat.RepeatingTimerControl {
        mockRepeatingTimer!
    }
}

class MockTimer: TimerControl {
    var cancelCallCount = 0
    func cancel() {
        cancelCallCount += 1
    }
}

class MockRepeatingTimer: RepeatingTimerControl {
    var resumeCallCount = 0
    var suspendCallCount = 0

    func resume() {
        resumeCallCount += 1
    }

    func suspend() {
        suspendCallCount += 1
    }
}
