//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type is designed to pre-process some incoming `Event` via middlewares before being published
class EventNotificationCenter: NotificationCenter {
    private(set) var middlewares: [EventMiddleware] = []
    
    /// The database used when evaluating middlewares.
    let database: DatabaseContainer
    
    /// Events are processed in batches to reduce database writes. This interval is the max number of seconds
    /// an event can wait before its processing started.
    ///
    /// Mutating this value doesn't affect the existing batch and the new value is applied for the following batch.
    ///
    var eventBatchPeriod: TimeInterval = 0.5
    
    @Atomic var pendingEvents: [Event] = []
    
    init(database: DatabaseContainer) {
        self.database = database
        super.init()
    }

    func add(middlewares: [EventMiddleware]) {
        self.middlewares.append(contentsOf: middlewares)
    }

    func add(middleware: EventMiddleware) {
        middlewares.append(middleware)
    }

    func process(_ event: Event) {
        var shouldScheduleProcessing = false
        _pendingEvents {
            shouldScheduleProcessing = $0.isEmpty
            $0.append(event)
        }
        
        if shouldScheduleProcessing {
            scheduleProcessing()
        }
    }
    
    /// Starts the timer and schedules the processing of events
    private func scheduleProcessing() {
        DispatchQueue.main.asyncAfter(deadline: .now() + eventBatchPeriod) { [weak self] in
            guard let self = self else { return }

            self.database.write { session in
                var eventsToProcess: [Event] = []
                self._pendingEvents {
                    eventsToProcess = $0
                    $0.removeAll()
                }
                
                eventsToProcess.forEach { event in
                    guard
                        let eventToPublish = self.middlewares.process(event: event, session: session)
                    else { return }

                    self.post(Notification(newEventReceived: eventToPublish, sender: self))
                }
            }
        }
    }
}
