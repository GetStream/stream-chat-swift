//
// Timers.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

protocol Timer {
  /// Schedules a new timer.
  ///
  /// - Parameters:
  ///   - timeInterval: The number of seconds after which the timer fires.
  ///   - queue: The queue on which the `onFire` callback is called.
  ///   - onFire: Called when the timer fires.
  static func schedule(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void)

  /// Schedules a new repeating timer.
  ///
  /// - Parameters:
  ///   - timeInterval: The number of seconds between timer fires.
  ///   - queue: The queue on which the `onFire` callback is called.
  ///   - onFire: Called when the timer fires.
  static func scheduleRepeating(timeInterval: TimeInterval,
                                queue: DispatchQueue,
                                onFire: @escaping () -> Void) -> TimerControl
}

/// Allows resuming and suspending of a timer.
protocol TimerControl {
  /// Resumes the timer.
  func resume()

  /// Pauses the timer.
  func suspend()
}

/// Default real-world implementations of timers.
struct DefaultTimer: Timer {
  static func schedule(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) {
    queue.asyncAfter(deadline: .now() + timeInterval, execute: onFire)
  }

  static func scheduleRepeating(timeInterval: TimeInterval,
                                queue: DispatchQueue,
                                onFire: @escaping () -> Void) -> TimerControl {
    RepeatingTimer(timeInterval: timeInterval, queue: queue, onFire: onFire)
  }
}

private class RepeatingTimer: TimerControl {
  private enum State {
    case suspended
    case resumed
  }

  private var state: State = .suspended
  private let timer: DispatchSourceTimer

  init(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) {
    self.timer = DispatchSource.makeTimerSource(queue: queue)
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
