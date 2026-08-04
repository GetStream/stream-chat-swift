//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    /// When set, the interval is derived from the query length instead of being fixed.
    private var policy: SearchDebouncePolicy?

    /// An initialiser that takes a TimeInterval parameter and sets the interval instance variable.
    ///
    /// - Parameters:
    ///   - interval: The interval that the debouncer will wait to execute the last debounced task.
    ///   - queue: An optional parameter that sets the queue on which the debounced task should be
    ///   executed. If not provided, a global queue with background quality of service is used by default.
    public init(
        _ interval: TimeInterval,
        queue: DispatchQueue = DispatchQueue.global(qos: .utility)
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
        
        if interval == .zero {
            block()
            return
        }

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

extension Debouncer {
    /// Creates a debouncer that derives its interval from a search debounce policy.
    ///
    /// - Parameters:
    ///   - policy: The policy used to derive the interval from the query length.
    ///   - queue: The queue the debounced task is executed on.
    init(
        policy: SearchDebouncePolicy,
        queue: DispatchQueue = DispatchQueue.global(qos: .utility)
    ) {
        self.init(0, queue: queue)
        self.policy = policy
    }
}

public extension Debouncer {
    /// Creates a debouncer that waits as long as the SDK's search controllers do, based on the
    /// length of the query: 500ms for 1-2 characters and 300ms for 3 or more.
    ///
    /// Short queries have low selectivity and are expensive for the backend, which is why they
    /// wait longer. Use with ``execute(queryLength:block:)`` when debouncing a search in the UI
    /// layer, so it stays in step with the rest of the SDK instead of hardcoding an interval.
    ///
    /// - Parameter queue: The queue the debounced task is executed on.
    static func search(queue: DispatchQueue = .main) -> Debouncer {
        Debouncer(policy: .default, queue: queue)
    }

    /// Executes `block` after the interval the policy defines for `queryLength`.
    ///
    /// Cancels any previously scheduled task. When the query is shorter than the policy's
    /// `minimumCharacterCount`, the pending task is cancelled and nothing is scheduled.
    ///
    /// - Parameters:
    ///   - queryLength: The length of the current search query.
    ///   - block: The block that will be executed as part of the debounced task.
    /// - Returns: `true` when the block was scheduled or run, `false` when the query was too short.
    @discardableResult
    mutating func execute(queryLength: Int, block: @escaping () -> Void) -> Bool {
        guard let policy else {
            execute(block: block)
            return true
        }
        guard policy.shouldPerformSearch(forQueryLength: queryLength) else {
            invalidate()
            return false
        }
        interval = policy.interval(forQueryLength: queryLength)
        execute(block: block)
        return true
    }
}
