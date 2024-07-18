//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public class ScheduledStreamTimer: StreamTimer {
    let interval: TimeInterval
    let fireOnStart: Bool
    var runLoop = RunLoop.current
    var timer: Foundation.Timer?
    public var onChange: (() -> Void)?

    public var isRunning: Bool {
        timer?.isValid ?? false
    }

    public init(interval: TimeInterval, fireOnStart: Bool = true) {
        self.interval = interval
        self.fireOnStart = fireOnStart
    }

    public func start() {
        stop()

        timer = Foundation.Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { _ in
            self.onChange?()
        }
        runLoop.add(timer!, forMode: .common)
        if fireOnStart {
            timer?.fire()
        }
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }
}
