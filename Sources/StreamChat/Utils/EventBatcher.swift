//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type that does events batching.
protocol EventBatcher {
    typealias Batch = [Event]
    
    /// The current batch of events.
    var currentBatch: Batch { get }
    
    /// Creates new batch processor.
    init(period: TimeInterval, handler: @escaping (Batch) -> Void)
    
    /// Adds the item to the current batch of events. If it's the first event also schedules batch processing
    /// that will happen when `period` has passed.
    ///
    /// - Parameter event: The event to add to the current batch.
    func append(_ event: Event)
    
    /// Ignores `period` and passes the current batch of events to handler as soon as possible.
    func processImmidiately()
}

extension Batcher: EventBatcher where Item == Event {}

final class Batcher<Item> {
    /// The batching period. If the item is added sonner then `period` has passed after the first item they will get into the same batch.
    private let period: TimeInterval
    /// The closure which processes the batch.
    private let handler: ([Item]) -> Void
    /// The serial queue where item appends and batch processing is happening on.
    private let queue = DispatchQueue(label: "co.getStream.Batch.\(Item.self)")
    /// The job scheduled on `queue` which will pass the current batch to `processor` when the deadline is met.
    private var task: DispatchWorkItem?
    /// The current batch of items.
    private(set) var currentBatch: [Item] = []
    
    init(
        period: TimeInterval,
        handler: @escaping ([Item]) -> Void
    ) {
        self.period = max(period, 0)
        self.handler = handler
    }
    
    func append(_ item: Item) {
        queue.async {
            self.currentBatch.append(item)
            
            if self.task == nil {
                self.scheduleProcessing()
            }
        }
    }
    
    func processImmidiately() {
        queue.async {
            self.process()
        }
    }

    private func scheduleProcessing() {
        let task = DispatchWorkItem {
            self.process()
        }
        
        self.task = task
        
        queue.asyncAfter(
            deadline: .now() + period,
            execute: task
        )
    }
    
    private func process() {
        handler(currentBatch)
        currentBatch.removeAll()
        task?.cancel()
        task = nil
    }
}
