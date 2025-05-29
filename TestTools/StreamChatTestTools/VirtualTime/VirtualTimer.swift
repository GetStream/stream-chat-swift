//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

struct VirtualTimeTimer: StreamChat.Timer {
    static let time = AllocatedUnfairLock<VirtualTime?>(nil)

    static func invalidate() {
        time.withLock {
            $0?.invalidate()
            $0 = nil
        }
    }

    static func schedule(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) -> TimerControl {
        Self.time.value!.scheduleTimer(
            interval: timeInterval,
            repeating: false,
            callback: { _ in onFire() }
        )
    }

    static func scheduleRepeating(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> RepeatingTimerControl {
        Self.time.value!.scheduleTimer(
            interval: timeInterval,
            repeating: true,
            callback: { _ in onFire() }
        )
    }

    static func currentTime() -> Date {
        Date(timeIntervalSinceReferenceDate: time.value!.currentTime)
    }
}

extension VirtualTime.TimerControl: TimerControl, RepeatingTimerControl {}
