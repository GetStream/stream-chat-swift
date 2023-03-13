//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol Debouncing {
    // Define a type alias for the handler closure.
    typealias Handler = () -> Void

    // Method to debounce the handler closure.
    func debounce(
        _ handler: @escaping Handler
    )

    // Method to cancel any pending debounce calls.
    func cancel()
}

open class Debouncer: Debouncing {
    // The minimum amount of time that must elapse between calls to debounce.
    private var interval: TimeInterval

    // The timer used to schwedule the handler closure.
    private var timer: Timer?

    public init(
        interval: TimeInterval
    ) {
        self.interval = interval
    }

    open func debounce(
        _ handler: @escaping Handler
    ) {
        // Invalidate any existing timer to
        // ensure that it doesn't execute the closure.
        timer?.invalidate()

        timer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: false
        ) { _ in
            // Schedule a new timer to execute the closure
            // after the debounce interval has elapsed.
            handler()
        }
    }

    open func cancel() {
        timer?.invalidate()
        timer = nil
    }
}
