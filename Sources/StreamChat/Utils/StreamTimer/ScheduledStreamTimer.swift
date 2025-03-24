//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public class ScheduledStreamTimer: StreamTimer, @unchecked Sendable {
    let runLoop = RunLoop.current
    var _timer: Foundation.Timer?
    public var onChange: (@Sendable() -> Void)? {
        get { queue.sync { _onChange } }
        set { queue.sync { _onChange = newValue } }
    }

    private var _onChange: (@Sendable() -> Void)?

    let interval: TimeInterval
    let fireOnStart: Bool
    let repeats: Bool
    private let queue = DispatchQueue(label: "io.getstream.scheduled-stream-timer", target: .global())

    public init(interval: TimeInterval, fireOnStart: Bool = true, repeats: Bool = true) {
        self.interval = interval
        self.fireOnStart = fireOnStart
        self.repeats = repeats
    }

    public var isRunning: Bool {
        queue.sync {
            _timer?.isValid ?? false
        }
    }

    public func start() {
        stop()

        queue.sync {
            let timer = Foundation.Timer.scheduledTimer(
                withTimeInterval: interval,
                repeats: repeats
            ) { _ in
                self.onChange?()
            }
            _timer = timer
            
            runLoop.add(timer, forMode: .common)
            if fireOnStart {
                timer.fire()
            }
        }
    }

    public func stop() {
        queue.sync {
            _timer?.invalidate()
            _timer = nil
        }
    }
}
