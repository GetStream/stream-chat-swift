//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type is designed to pre-process some incoming `Event` via middlewares before being published
class EventNotificationCenter: NotificationCenter {
    private(set) var middlewares: [EventMiddleware] = []
    
    /// The database used when evaluating middlewares.
    let database: DatabaseContainer
    
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

    func process(_ events: [Event], post: Bool = true, completion: (() -> Void)? = nil) {
        var eventsToPost = [Event]()
        
        database.write({ session in
            eventsToPost = events.compactMap {
                self.middlewares.process(event: $0, session: session)
            }
        }, completion: { _ in
            DispatchQueue.main.sync {
                if post {
                    eventsToPost.forEach { self.post(Notification(newEventReceived: $0, sender: self)) }
                }
                
                completion?()
            }
        })
    }
    
    func process(_ event: Event, post: Bool = true, completion: (() -> Void)? = nil) {
        process([event], post: post, completion: completion)
    }
}
