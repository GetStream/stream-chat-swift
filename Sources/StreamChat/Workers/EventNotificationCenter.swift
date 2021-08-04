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
        var event = event
        switch event {
        case var messageSpecificEvent as MessageSpecificEvent:
            messageSpecificEvent.savedData = SavedEventData(
                user: { [weak database] in database?.viewContext.user(id: messageSpecificEvent.userId)?.asModel() },
                channel: { [weak database] in database?.viewContext.channel(cid: messageSpecificEvent.cid)?.asModel() },
                message: { [weak database] in database?.viewContext.message(id: messageSpecificEvent.messageId)?.asModel() },
                underlyingContext: database.viewContext
            )
            event = messageSpecificEvent
        case var memberEvent as MemberEvent:
            memberEvent.savedData = SavedEventData(
                member: { [weak database] in
                    database?.viewContext.member(userId: memberEvent.memberUserId, cid: memberEvent.cid)?.asModel()
                },
                underlyingContext: database.viewContext
            )
            event = memberEvent
        case var userSpecificEvent as UserSpecificEvent:
            userSpecificEvent.savedData = SavedEventData(
                user: { [weak database] in database?.viewContext.user(id: userSpecificEvent.userId)?.asModel() },
                underlyingContext: database.viewContext
            )
            event = userSpecificEvent
        case var channelSpecificEvent as ChannelSpecificEvent:
            channelSpecificEvent.savedData = SavedEventData(
                channel: { [weak database] in database?.viewContext.channel(cid: channelSpecificEvent.cid)?.asModel() },
                underlyingContext: database.viewContext
            )
            event = channelSpecificEvent
        case var currentUserEvent as CurrentUserEvent:
            currentUserEvent.savedData = SavedEventData(
                currentUser: { [weak database] in database?.viewContext.currentUser?.asModel() },
                underlyingContext: database.viewContext
            )
            event = currentUserEvent
        default:
            break
        }
        
        var shouldScheduleProcessing = false
        _pendingEvents {
            shouldScheduleProcessing = $0.isEmpty
            $0.append(event)
        }
        
        if shouldScheduleProcessing {
            scheduleProcessing()
        }
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
        database.write { session in
            // We don't want to publish `HealthCheckEvent`, so we discard the output
            _ = self.middlewares.process(event: healthCheckEvent, session: session)
        } completion: { _ in
            completion(healthCheckEvent.connectionId)
        }
    }
    
    /// Starts the timer and schedules the processing of events
    private func scheduleProcessing() {
        DispatchQueue.main.asyncAfter(deadline: .now() + eventBatchPeriod) { [weak self] in
            guard let self = self else { return }
            
            var eventsToPublish = [Event]()
            
            self.database.write { session in
                var eventsToProcess: [Event] = []
                self._pendingEvents {
                    eventsToProcess = $0
                    $0.removeAll()
                }
                
                eventsToPublish = eventsToProcess.compactMap { self.middlewares.process(event: $0, session: session) }
            } completion: { error in
                if let error = error {
                    log.error("Error when saving events: \(error)")
                }
                eventsToPublish.forEach { self.post(Notification(newEventReceived: $0, sender: self)) }
            }
        }
    }
}
