//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// The type is designed to pre-process some incoming `Event` via middlewares before being published
class PersistentEventNotificationCenter: NotificationCenter, EventNotificationCenter, @unchecked Sendable {
    private(set) var middlewares: [EventMiddleware] = []

    /// The database used when evaluating middlewares.
    let database: DatabaseContainer

    var eventPostingQueue = DispatchQueue(label: "io.getstream.event-notification-center")

    // Contains the ids of the new messages that are going to be added during the ongoing process
    private(set) var newMessageIds: Set<MessageId> = Set()

    /// Handles manual event processing for channels that opt out of middleware processing.
    private let manualEventHandler: ManualEventHandler

    init(
        database: DatabaseContainer,
        manualEventHandler: ManualEventHandler? = nil
    ) {
        self.database = database
        self.manualEventHandler = manualEventHandler ?? ManualEventHandler(database: database)
        super.init()
    }

    /// Registers a channel for manual event handling.
    ///
    /// The middleware's will not process events for this channel.
    func registerManualEventHandling(for cid: ChannelId) {
        manualEventHandler.register(channelId: cid)
    }

    /// Unregister a channel for manual event handling.
    func unregisterManualEventHandling(for cid: ChannelId) {
        manualEventHandler.unregister(channelId: cid)
    }

    func add(middlewares: [EventMiddleware]) {
        self.middlewares.append(contentsOf: middlewares)
    }

    func add(middleware: EventMiddleware) {
        middlewares.append(middleware)
    }

    func process(_ events: [Event], postNotifications: Bool = true, completion: (@Sendable () -> Void)? = nil) {
        let unwrappedEvents: [(event: Event, wsEvent: WSEvent?)] = events.map {
            // WSEvent is the enum whose associated values are the generated EventDTO payloads.
            if let wsEvent = $0 as? WSEvent {
                return (event: wsEvent.rawValue, wsEvent: wsEvent)
            }
            return (event: $0, wsEvent: nil)
        }
        let processingEventsDebugMessage: () -> String = {
            let eventNames = unwrappedEvents.map(\.event.name)
            return "Processing Events: \(eventNames)"
        }
        log.debug(processingEventsDebugMessage(), subsystems: .webSocket)

        let messageIds: [MessageId] = unwrappedEvents.compactMap {
            let event = $0.event
            return (event as? MessageNewEventDTO)?.message.id ?? (event as? NotificationNewMessageEventDTO)?.message.id
        }

        nonisolated(unsafe) var eventsToPost = [Event]()
        nonisolated(unsafe) var middlewareEvents = [(event: Event, wsEvent: WSEvent?)]()
        nonisolated(unsafe) var manualHandlingEvents = [Event]()

        database.write({ session in
            unwrappedEvents.forEach { input in
                if let manualEvent = self.manualEventHandler.handle(input.event) {
                    manualHandlingEvents.append(manualEvent)
                } else {
                    middlewareEvents.append(input)
                }
            }

            self.newMessageIds = Set(messageIds.compactMap {
                !session.messageExists(id: $0) ? $0 : nil
            })

            eventsToPost.append(contentsOf: manualHandlingEvents)
            eventsToPost.append(contentsOf: middlewareEvents.compactMap {
                self.middlewares.process(event: $0.event, wsEvent: $0.wsEvent, session: session)
            })

            self.newMessageIds = []
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

extension PersistentEventNotificationCenter {
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
