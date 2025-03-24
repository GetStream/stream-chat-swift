//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

protocol Timer {
    /// Schedules a new timer.
    ///
    /// - Parameters:
    ///   - timeInterval: The number of seconds after which the timer fires.
    ///   - queue: The queue on which the `onFire` callback is called.
    ///   - onFire: Called when the timer fires.
    /// - Returns: `TimerControl` where you can cancel the timer.
    @discardableResult
    static func schedule(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) -> TimerControl

    /// Schedules a new repeating timer.
    ///
    /// - Parameters:
    ///   - timeInterval: The number of seconds between timer fires.
    ///   - queue: The queue on which the `onFire` callback is called.
    ///   - onFire: Called when the timer fires.
    /// - Returns: `RepeatingTimerControl` where you can suspend and resume the timer.
    static func scheduleRepeating(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> RepeatingTimerControl

    /// Returns the current date and time.
    static func currentTime() -> Date
}

extension Timer {
    static func currentTime() -> Date {
        Date()
    }
}

/// Allows resuming and suspending of a timer.
protocol RepeatingTimerControl: Sendable {
    /// Resumes the timer.
    func resume()

    /// Pauses the timer.
    func suspend()
}

/// Allows cancelling a timer.
protocol TimerControl: Sendable {
    /// Cancels the timer.
    func cancel()
}

extension DispatchWorkItem: TimerControl {}
#if compiler(>=6.0)
extension DispatchWorkItem: @retroactive @unchecked Sendable {}
#else
extension DispatchWorkItem: @unchecked Sendable {}
#endif

/// Default real-world implementations of timers.
struct DefaultTimer: Timer {
    @discardableResult
    static func schedule(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> TimerControl {
        let worker = DispatchWorkItem(block: onFire)
        queue.asyncAfter(deadline: .now() + timeInterval, execute: worker)
        return worker
    }

    static func scheduleRepeating(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> RepeatingTimerControl {
        RepeatingTimer(timeInterval: timeInterval, queue: queue, onFire: onFire)
    }
}

private final class RepeatingTimer: RepeatingTimerControl {
    private enum State {
        case suspended
        case resumed
    }

    private let queue = DispatchQueue(label: "io.getstream.repeating-timer")
    nonisolated(unsafe) private var _state: State = .suspended
    nonisolated(unsafe) private let _timer: DispatchSourceTimer

    init(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) {
        _timer = DispatchSource.makeTimerSource(queue: queue)
        _timer.schedule(deadline: .now() + .milliseconds(Int(timeInterval)), repeating: timeInterval, leeway: .seconds(1))
        _timer.setEventHandler(handler: onFire)
    }

    deinit {
        _timer.setEventHandler {}
        _timer.cancel()
        // If the timer is suspended, calling cancel without resuming
        // triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
        if _state == .suspended {
            _timer.resume()
        }
    }

    func resume() {
        queue.async {
            if self._state == .resumed {
                return
            }

            self._state = .resumed
            self._timer.resume()
        }
    }

    func suspend() {
        queue.async {
            if self._state == .suspended {
                return
            }

            self._state = .suspended
            self._timer.suspend()
        }
    }
}
