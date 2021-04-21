//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
protocol RepeatingTimerControl {
    /// Resumes the timer.
    func resume()
    
    /// Pauses the timer.
    func suspend()
}

/// Allows cancelling a timer.
protocol TimerControl {
    /// Cancels the timer.
    func cancel()
}

extension DispatchWorkItem: TimerControl {}

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

private class RepeatingTimer: RepeatingTimerControl {
    private enum State {
        case suspended
        case resumed
    }
    
    private var state: State = .suspended
    private let timer: DispatchSourceTimer
    
    init(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) {
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + .milliseconds(Int(timeInterval)), repeating: timeInterval, leeway: .seconds(1))
        timer.setEventHandler(handler: onFire)
    }
    
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        // If the timer is suspended, calling cancel without resuming
        // triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
        resume()
    }
    
    func resume() {
        if state == .resumed {
            return
        }
        
        state = .resumed
        timer.resume()
    }
    
    func suspend() {
        if state == .suspended {
            return
        }
        
        state = .suspended
        timer.suspend()
    }
}
