//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

protocol Debouncing {
    // Define a type alias for the handler closure.
    typealias Handler = () -> Void

    // Method to debounce the handler closure.
    func debounce(
        _ handler: @escaping Handler
    )

    // Method to cancel any pending debounce calls.
    func cancel()
}

final class Debouncer: Debouncing {
    // The minimum amount of time that must elapse between calls to debounce.
    private var interval: TimeInterval

    // The timer used to schedule the handler closure.
    private var timer: TimerControl?

    init(
        interval: TimeInterval
    ) {
        self.interval = interval
    }

    func debounce(
        _ handler: @escaping Handler
    ) {
        // Invalidate any existing timer to
        // ensure that it doesn't execute the closure.
        timer?.cancel()

        timer = DefaultTimer.schedule(
            timeInterval: interval,
            queue: .main,
            onFire: handler
        )
    }

    func cancel() {
        timer?.cancel()
        timer = nil
    }
}
