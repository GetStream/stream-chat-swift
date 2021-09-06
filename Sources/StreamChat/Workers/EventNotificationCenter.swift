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
    
    /// Appends the given events to the current batch and starts batch processing immidiately.
    func addToCurrentBatchAndProcessImmediately(
        _ events: [Event],
        completion: @escaping () -> Void = {}
    ) {
        var eventsToProcess: [Event] = []
        _pendingEvents {
            eventsToProcess = $0 + events
            $0.removeAll()
        }
        feedEventsToMiddlewares(eventsToProcess, completion: completion)
    }
    
    /// Custom overload for `HealthCheckEvent`
    ///
    /// When we receive this event, we first create the `CurrentUserDTO`
    /// and then inform the `connectionIdWaiters` of `ChatClient`
    /// that we're connected. Using the normal `process` func, by the time
    /// we inform the waiters, DB save is not finished so `CurrentUserDTO`
    /// does not exist in DB yet. Using this overload makes sure that
    /// we process the event fully before calling completion closures.
    func process(_ healthCheckEvent: HealthCheckEvent, completion: @escaping ((ConnectionId) -> Void)) {
        addToCurrentBatchAndProcessImmediately([healthCheckEvent]) {
            completion(healthCheckEvent.connectionId)
        }
    }
    
    /// Starts the timer and schedules the processing of events
    private func scheduleProcessing() {
        DispatchQueue.main.asyncAfter(deadline: .now() + eventBatchPeriod) { [weak self] in
            guard let self = self else { return }

            var eventsToProcess: [Event] = []
            self._pendingEvents {
                eventsToProcess = $0
                $0.removeAll()
            }
            
            self.feedEventsToMiddlewares(eventsToProcess)
        }
    }
    
    /// Opens database session and feeds events to middlewares one by one respecting the order.
    /// When an event is processed it is posted (except events of `HealthCheckEvent` type).
    ///
    /// - Parameters:
    ///   - events: The list of events to be processed.
    ///   - completion: The completion that will be invoked .
    private func feedEventsToMiddlewares(
        _ events: [Event],
        completion: @escaping () -> Void = {}
    ) {
        database.write({ session in
            for event in events {
                guard
                    let eventToPublish = self.middlewares.process(event: event, session: session),
                    !(eventToPublish is HealthCheckEvent)
                else { continue }
                
                self.post(Notification(newEventReceived: eventToPublish, sender: self))
            }
        }, completion: { _ in
            completion()
        })
    }
}
