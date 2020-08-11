//
//  VirtualTimers.swift
//  StreamChatClientTests
//
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatClient

struct VirtualTimeTimer: StreamChatClient.Timer {
    
    static var time: VirtualTime!
    
    static func schedule(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) -> TimerControl {
        Self.time.scheduleTimer(interval: timeInterval,
                                repeating: false,
                                callback: { _ in onFire() })
    }
    
    static func scheduleRepeating(timeInterval: TimeInterval,
                                  queue: DispatchQueue,
                                  onFire: @escaping () -> Void) -> RepeatingTimerControl {
        Self.time.scheduleTimer(interval: timeInterval,
                                repeating: true,
                                callback: { _ in onFire() })
    }
}

extension VirtualTime.TimerControl: TimerControl, RepeatingTimerControl {}
