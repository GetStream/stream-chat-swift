//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// The type is designed to pre-process some incoming `Event` via middlewares before being published
class EventNotificationCenter: NotificationCenter, @unchecked Sendable {
    private let queue = DispatchQueue(label: "io.getstream.event-notification-center-sync", target: .global())
    private(set) var middlewares: [EventMiddleware] {
        get { queue.sync { _middlewares } }
        set { queue.sync { _middlewares = newValue } }
    }

    private var _middlewares: [EventMiddleware] = []

    /// The database used when evaluating middlewares.
    let database: DatabaseContainer

    var eventPostingQueue = DispatchQueue(label: "io.getstream.event-notification-center")

    // Contains the ids of the new messages that are going to be added during the ongoing process
    private(set) var newMessageIds: Set<MessageId> {
        get { queue.sync { _newMessageIds } }
        set { queue.sync { _newMessageIds = newValue } }
    }

    private var _newMessageIds: Set<MessageId> = Set()

    init(database: DatabaseContainer) {
        self.database = database
        super.init()
    }

    func add(middlewares: [EventMiddleware]) {
        queue.sync {
            _middlewares.append(contentsOf: middlewares)
        }
    }

    func add(middleware: EventMiddleware) {
        queue.sync {
            _middlewares.append(middleware)
        }
    }

    func process(_ events: [Event], postNotifications: Bool = true, completion: (@Sendable() -> Void)? = nil) {
        let processingEventsDebugMessage: () -> String = {
            let eventNames = events.map(\.name)
            return "Processing Events: \(eventNames)"
        }
        log.debug(processingEventsDebugMessage(), subsystems: .webSocket)

        let messageIds: [MessageId] = events.compactMap {
            ($0 as? MessageNewEventDTO)?.message.id ?? ($0 as? NotificationMessageNewEventDTO)?.message.id
        }

        database.write(converting: { session in
            self.newMessageIds = Set(messageIds.compactMap {
                !session.messageExists(id: $0) ? $0 : nil
            })

            let eventsToPost = events.compactMap {
                self.middlewares.process(event: $0, session: session)
            }

            self.newMessageIds = []
            return eventsToPost
        }, completion: { result in
            guard let eventsToPost = result.value, postNotifications else {
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
    func process(_ event: Event, postNotification: Bool = true, completion: (@Sendable() -> Void)? = nil) {
        process([event], postNotifications: postNotification, completion: completion)
    }
}

extension EventNotificationCenter {
    func subscribe<E>(
        to event: E.Type,
        filter: @escaping (E) -> Bool = { _ in true },
        handler: @escaping (E) -> Void
    ) -> AnyCancellable where E: Event {
        publisher(for: .NewEventReceived)
            .compactMap { $0.event as? E }
            .filter(filter)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
    }
    
    func subscribe(
        filter: @escaping (Event) -> Bool = { _ in true },
        handler: @escaping (Event) -> Void
    ) -> AnyCancellable {
        publisher(for: .NewEventReceived)
            .compactMap(\.event)
            .filter(filter)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
    }
    
    static func channelFilter(cid: ChannelId, event: Event) -> Bool {
        switch event {
        case let channelEvent as ChannelSpecificEvent:
            return channelEvent.cid == cid
        case let channelEvent as UnknownChannelEvent:
            return channelEvent.cid == cid
        default:
            return false
        }
    }
}
