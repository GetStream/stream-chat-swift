//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public class ScheduledStreamTimer: StreamTimer {
    var runLoop = RunLoop.current
    var timer: Foundation.Timer?
    public var onChange: (() -> Void)?

    let interval: TimeInterval
    let fireOnStart: Bool
    let repeats: Bool

    public init(interval: TimeInterval, fireOnStart: Bool = true, repeats: Bool = true) {
        self.interval = interval
        self.fireOnStart = fireOnStart
        self.repeats = repeats
    }

    public var isRunning: Bool {
        timer?.isValid ?? false
    }

    public func start() {
        stop()

        timer = Foundation.Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: repeats
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
