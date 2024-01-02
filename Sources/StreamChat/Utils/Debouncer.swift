//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A public struct that allows you to execute a block of code after a certain time interval.
public struct Debouncer {
    /// The interval that we will wait before we execute the last debounced task.
    private var interval: TimeInterval

    /// An instance of DispatchQueue  that will be used to enqueue the debounced tasks.
    private let queue: DispatchQueue

    /// An instance of DispatchWorkItem that will be used to reference the last debounced task.
    private var job: DispatchWorkItem?

    /// An initialiser that takes a TimeInterval parameter and sets the interval instance variable.
    ///
    /// - Parameters:
    ///   - interval: The interval that the debouncer will wait to execute the last debounced task.
    ///   - queue: An optional parameter that sets the queue on which the debounced task should be
    ///   executed. If not provided, a global queue with background quality of service is used by default.
    public init(
        _ interval: TimeInterval,
        queue: DispatchQueue = DispatchQueue.global(qos: .background)
    ) {
        self.interval = interval
        self.queue = queue
    }

    /// A public mutating function that takes a block parameter and executes it after a certain time interval.
    ///
    /// - Parameter block: The block that will be executed as part of the debounced task.
    public mutating func execute(block: @escaping () -> Void) {
        /// Cancels the current job if there is one.
        job?.cancel()
        /// Creates a new job with the given block and assigns it to the newJob constant.
        let newJob = DispatchWorkItem { block() }
        /// Schedules the new job to be executed after a certain time interval on the provided queue.
        queue.asyncAfter(deadline: .now() + interval, execute: newJob)

        /// Sets the job variable to reference the new job.
        job = newJob
    }

    /// A public function that cancels the current job if there is one.
    public func invalidate() {
        job?.cancel()
    }
}
