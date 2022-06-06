//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type is designed to pre-process some incoming `Event` via middlewares before being published
class EventNotificationCenter: NotificationCenter {
    private(set) var middlewares: [EventMiddleware] = []
    
    /// The database used when evaluating middlewares.
    let database: DatabaseContainer
    
    // We post events on a queue different from database.writable context
    // queue to prevent a deadlock happening when @CoreDataLazy (with `context.performAndWait` inside)
    // model is accessed in event handlers.
    var eventPostingQueue = DispatchQueue(label: "io.getstream.event-notification-center")
    
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

    func process(_ events: [Event], postNotifications: Bool = true, completion: (() -> Void)? = nil) {
        let processingEventsDebugMessage: () -> String = {
            let eventNames = events.compactMap { ($0 as? EventDTO)?.name }
            return "Processing Events: \(eventNames)"
        }
        log.debug(processingEventsDebugMessage, subsystems: .webSocket)

        var eventsToPost = [Event]()
        database.write({ session in
            eventsToPost = events.compactMap {
                self.middlewares.process(event: $0, session: session)
            }
        }, completion: { _ in
            guard postNotifications else {
                completion?()
                return
            }
            
            self.eventPostingQueue.async {
                eventsToPost.forEach { self.post(Notification(newEventReceived: $0, sender: self)) }
                completion?()
            }
        })
    }
}

extension EventNotificationCenter {
    func process(_ event: Event, postNotification: Bool = true, completion: (() -> Void)? = nil) {
        process([event], postNotifications: postNotification, completion: completion)
    }
}
