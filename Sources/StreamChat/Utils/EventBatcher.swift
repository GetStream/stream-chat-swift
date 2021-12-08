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
    init(period: TimeInterval, timerType: Timer.Type, handler: @escaping (Batch) -> Void)
    
    /// Adds the item to the current batch of events. If it's the first event also schedules batch processing
    /// that will happen when `period` has passed.
    ///
    /// - Parameter event: The event to add to the current batch.
    func append(_ event: Event)
    
    /// Ignores `period` and passes the current batch of events to handler as soon as possible.
    func processImmediately()
}

extension Batcher: EventBatcher where Item == Event {}

final class Batcher<Item> {
    /// The batching period. If the item is added sonner then `period` has passed after the first item they will get into the same batch.
    private let period: TimeInterval
    /// The time used to create timers.
    private let timerType: Timer.Type
    /// The timer that  calls `processor` when fired.
    private var batchProcessingTimer: TimerControl?
    /// The closure which processes the batch.
    private let handler: ([Item]) -> Void
    /// The serial queue where item appends and batch processing is happening on.
    private let queue = DispatchQueue(label: "io.getstream.Batch.\(Item.self)")
    /// The current batch of items.
    private(set) var currentBatch: [Item] = []
    
    init(
        period: TimeInterval,
        timerType: Timer.Type = DefaultTimer.self,
        handler: @escaping ([Item]) -> Void
    ) {
        self.period = max(period, 0)
        self.timerType = timerType
        self.handler = handler
    }
    
    func append(_ item: Item) {
        timerType.schedule(timeInterval: 0, queue: queue) {
            self.currentBatch.append(item)
            
            guard self.batchProcessingTimer == nil else { return }
            
            self.batchProcessingTimer = self.timerType.schedule(
                timeInterval: self.period,
                queue: self.queue,
                onFire: self.process
            )
        }
    }
    
    func processImmediately() {
        timerType.schedule(timeInterval: 0, queue: queue) {
            self.process()
        }
    }
    
    private func process() {
        handler(currentBatch)
        currentBatch.removeAll()
        batchProcessingTimer?.cancel()
        batchProcessingTimer = nil
    }
}
