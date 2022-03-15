//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

/// This class allows simulating time-based events in tests.
class VirtualTime {
    typealias Seconds = TimeInterval
    
    var scheduledTimers: [VirtualTime.TimerControl] = []
    var timestampToFiredTimers: [TimeInterval: [VirtualTime.TimerControl]] = [:]

    var currentTime: Seconds
    
    enum State {
        case running
        case waiting
        case stopped
    }
    
    var state: State = .stopped
    
    init(initialTime: TimeInterval = 0) {
        currentTime = initialTime
    }
    
    /// Simulates running the virtual time.
    ///
    /// - Parameter numberOfSeconds: The number of virtual seconds the time should advance of. If `nil` it runs until
    /// all timers are in the inactive state.
    func run(numberOfSeconds: Seconds? = nil) {
        let targetTime: Seconds = numberOfSeconds.map { $0 + currentTime } ?? .greatestFiniteMagnitude
        state = .running
        
        while true {
            let timersToFire = scheduledTimers
                .filter { timer in timer.shouldeFire(at: currentTime) }
                .filter { timer in !timestampToFiredTimers[currentTime, default: []].contains(where: { $0 === timer }) }
            timersToFire.forEach { $0.callback($0) }
            timestampToFiredTimers[currentTime, default: []] += timersToFire

            let nextFireTime = scheduledTimers
                .compactMap { $0.nextFireTime(after: currentTime) }
                .sorted()
                .first
            
            guard let nextFireAt = nextFireTime else {
                // We're done, no active timers left
                break
            }
            
            guard nextFireAt <= targetTime else {
                // We're done, some timers are still active but we've reached the target time
                currentTime = targetTime
                break
            }
            
            // Bump current time
            currentTime = nextFireAt
        }
        
        if numberOfSeconds == nil {
            state = .waiting
        } else {
            state = .stopped
        }
    }
    
    func scheduleTimer(interval: TimeInterval, repeating: Bool, callback: @escaping (TimerControl) -> Void) -> TimerControl {
        let timer = TimerControl(
            scheduledFireTime: currentTime + interval,
            repeatingPeriod: repeating ? interval : 0,
            callback: callback
        )
        scheduledTimers.append(timer)
        
        if state == .waiting {
            run()
        }
        
        return timer
    }
}

extension VirtualTime {
    /// Internal representation of a timer scheduled with `VirtualTime`. Not meant to be used directly.
    class TimerControl {
        private(set) var isActive = true
        
        var repeatingPeriod: TimeInterval
        var scheduledFireTime: TimeInterval
        var callback: (TimerControl) -> Void
        
        var isRepeated: Bool {
            repeatingPeriod > 0
        }
        
        init(scheduledFireTime: TimeInterval, repeatingPeriod: TimeInterval, callback: @escaping (TimerControl) -> Void) {
            self.repeatingPeriod = repeatingPeriod
            self.scheduledFireTime = scheduledFireTime
            self.callback = callback
        }
        
        func resume() {
            isActive = true
        }
        
        func suspend() {
            isActive = false
        }
        
        func cancel() {
            isActive = false
        }
        
        func shouldeFire(at time: TimeInterval) -> Bool {
            guard isActive else { return false }
            
            if isRepeated {
                return time >= scheduledFireTime && time.truncatingRemainder(dividingBy: repeatingPeriod).isZero
            } else {
                return scheduledFireTime == time
            }
        }
        
        func nextFireTime(after time: TimeInterval) -> TimeInterval? {
            guard isActive else { return nil }
            
            if isRepeated {
                let periodsPassed = Int(time / repeatingPeriod)
                let nextPeriod = TimeInterval(periodsPassed + 1)
                return nextPeriod * repeatingPeriod
            } else {
                return scheduledFireTime > time ? scheduledFireTime : nil
            }
        }
    }
}
