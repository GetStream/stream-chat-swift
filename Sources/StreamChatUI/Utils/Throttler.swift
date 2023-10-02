//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// A throttler implementation. The action provided will only be executed if the last action executed has passed an amount of time.
/// Based on the implementation from Apple: https://developer.apple.com/documentation/combine/anypublisher/throttle(for:scheduler:latest:)
class Throttler {
    private var workItem: DispatchWorkItem?
    private let queue = DispatchQueue(label: "com.stream.throttler", qos: .background)
    private var previousRun: Date = Date.distantPast
    let interval: TimeInterval
    let broadcastLatestEvent: Bool

    /// - Parameters:
    ///   - interval: The interval that an action can be executed.
    ///   - broadcastLatestEvent: A Boolean value that indicates whether we should be using the first or last event of the ones that are being throttled.
    ///   This last action will have a delay of the provided interval until it is executed.
    init(interval: TimeInterval, broadcastLatestEvent: Bool = true) {
        self.interval = interval
        self.broadcastLatestEvent = broadcastLatestEvent
    }

    /// Throttle an action. It will cancel the previous action if exists, and it will execute the action immediately
    /// if the last action executed was past the interval provided. If not, it will only be executed after a delay.
    /// - Parameter action: The closure to be performed.
    func throttle(_ action: @escaping () -> Void) {
        workItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let workItem = self?.workItem, !workItem.isCancelled else { return }
            action()
            self?.previousRun = Date()
            self?.workItem = nil
        }

        self.workItem = workItem

        let timeSinceLastRun = Date().timeIntervalSince(previousRun)
        let delay = timeSinceLastRun > interval ? 0 : interval
        // If the delay is 0, we always execute the action immediately.
        // If the delay is bigger than 0, we only execute it if `latest` was enabled.
        if delay == 0 || delay > 0 && broadcastLatestEvent {
            queue.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }

    /// Cancel any active action.
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}
