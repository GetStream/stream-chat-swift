//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// The type is designed to pre-process some incoming `Event` via middlewares before being published
class EventNotificationCenter: NotificationCenter, @unchecked Sendable {
    private(set) var middlewares: [EventMiddleware] = []

    /// The database used when evaluating middlewares.
    let database: DatabaseContainer

    var eventPostingQueue = DispatchQueue(label: "io.getstream.event-notification-center")

    // Contains the ids of the new messages that are going to be added during the ongoing process
    private(set) var newMessageIds: Set<MessageId> = Set()

    // The channels for which events will not be processed by the middlewares.
    private var manualEventHandlingChannelIds: Set<ChannelId> = []

    init(
        database: DatabaseContainer
    ) {
        self.database = database
        super.init()
    }

    /// Registers a channel for manual event handling.
    ///
    /// The middleware's will not process events for this channel.
    func registerManualEventHandling(for cid: ChannelId) {
        eventPostingQueue.async { [weak self] in
            self?.manualEventHandlingChannelIds.insert(cid)
        }
    }

    func add(middlewares: [EventMiddleware]) {
        self.middlewares.append(contentsOf: middlewares)
    }

    func add(middleware: EventMiddleware) {
        middlewares.append(middleware)
    }

    func process(_ events: [Event], postNotifications: Bool = true, completion: (() -> Void)? = nil) {
        let processingEventsDebugMessage: () -> String = {
            let eventNames = events.map(\.name)
            return "Processing Events: \(eventNames)"
        }
        log.debug(processingEventsDebugMessage(), subsystems: .webSocket)

        let messageIds: [MessageId] = events.compactMap {
            ($0 as? MessageNewEventDTO)?.message.id ?? ($0 as? NotificationMessageNewEventDTO)?.message.id
        }

        var eventsToPost = [Event]()
        var middlewareEvents = [Event]()
        var manualHandlingEvents = [Event]()

        database.write({ session in
            events.forEach { event in
                guard let eventDTO = event as? EventDTO else {
                    middlewareEvents.append(event)
                    return
                }
                if let cid = eventDTO.payload.cid, self.manualEventHandlingChannelIds.contains(cid) {
                    manualHandlingEvents.append(event)
                } else {
                    middlewareEvents.append(event)
                }
            }

            let manualEvents = self.convertManualEventsToDomain(manualHandlingEvents)
            eventsToPost.append(contentsOf: manualEvents)

            self.newMessageIds = Set(messageIds.compactMap {
                !session.messageExists(id: $0) ? $0 : nil
            })

            eventsToPost.append(contentsOf: middlewareEvents.compactMap {
                self.middlewares.process(event: $0, session: session)
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

    private func convertManualEventsToDomain(_ events: [Event]) -> [Event] {
        events.compactMap { event in
            guard let eventDTO = event as? EventDTO else {
                return nil
            }

            let eventPayload = eventDTO.payload

            guard let cid = eventPayload.cid else {
                return nil
            }

            switch eventPayload.eventType {
            case .messageNew:
                return createMessageNewEvent(from: eventPayload, cid: cid)
                
            case .messageUpdated:
                return createMessageUpdatedEvent(from: eventPayload, cid: cid)
                
            case .messageDeleted:
                return createMessageDeletedEvent(from: eventPayload, cid: cid)
                
            case .reactionNew:
                return createReactionNewEvent(from: eventPayload, cid: cid)
                
            case .reactionUpdated:
                return createReactionUpdatedEvent(from: eventPayload, cid: cid)
                
            case .reactionDeleted:
                return createReactionDeletedEvent(from: eventPayload, cid: cid)
                
            default:
                return nil
            }
        }
    }
    
    // MARK: - Event Creation Helpers
    
    private func createMessageNewEvent(from payload: EventPayload, cid: ChannelId) -> MessageNewEvent? {
        guard
            let userPayload = payload.user,
            let messagePayload = payload.message,
            let createdAt = payload.createdAt,
            let channel = try? database.writableContext.channel(cid: cid)?.asModel(),
            let currentUserId = database.writableContext.currentUser?.user.id,
            let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)
        else {
            return nil
        }

        return MessageNewEvent(
            user: userPayload.asModel(),
            message: message,
            channel: channel,
            createdAt: createdAt,
            watcherCount: payload.watcherCount,
            unreadCount: payload.unreadCount.map {
                .init(
                    channels: $0.channels ?? 0,
                    messages: $0.messages ?? 0,
                    threads: $0.threads ?? 0
                )
            }
        )
    }
    
    private func createMessageUpdatedEvent(from payload: EventPayload, cid: ChannelId) -> MessageUpdatedEvent? {
        guard
            let userPayload = payload.user,
            let messagePayload = payload.message,
            let createdAt = payload.createdAt,
            let currentUserId = database.writableContext.currentUser?.user.id,
            let channel = try? database.writableContext.channel(cid: cid)?.asModel(),
            let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)
        else { return nil }
        
        return MessageUpdatedEvent(
            user: userPayload.asModel(),
            channel: channel,
            message: message,
            createdAt: createdAt
        )
    }
    
    private func createMessageDeletedEvent(from payload: EventPayload, cid: ChannelId) -> MessageDeletedEvent? {
        guard
            let messagePayload = payload.message,
            let createdAt = payload.createdAt,
            let currentUserId = database.writableContext.currentUser?.user.id,
            let channel = try? database.writableContext.channel(cid: cid)?.asModel(),
            let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)
        else { return nil }
        
        let userPayload = payload.user
        
        return MessageDeletedEvent(
            user: userPayload?.asModel(),
            channel: channel,
            message: message,
            createdAt: createdAt,
            isHardDelete: payload.hardDelete
        )
    }
    
    private func createReactionNewEvent(from payload: EventPayload, cid: ChannelId) -> ReactionNewEvent? {
        guard
            let userPayload = payload.user,
            let messagePayload = payload.message,
            let reactionPayload = payload.reaction,
            let createdAt = payload.createdAt,
            let currentUserId = database.writableContext.currentUser?.user.id,
            let channel = try? database.writableContext.channel(cid: cid)?.asModel(),
            let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)
        else { return nil }
        
        return ReactionNewEvent(
            user: userPayload.asModel(),
            cid: cid,
            message: message,
            reaction: reactionPayload.asModel(),
            createdAt: createdAt
        )
    }
    
    private func createReactionUpdatedEvent(from payload: EventPayload, cid: ChannelId) -> ReactionUpdatedEvent? {
        guard
            let userPayload = payload.user,
            let messagePayload = payload.message,
            let reactionPayload = payload.reaction,
            let createdAt = payload.createdAt,
            let currentUserId = database.writableContext.currentUser?.user.id,
            let channel = try? database.writableContext.channel(cid: cid)?.asModel(),
            let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)
        else { return nil }
        
        return ReactionUpdatedEvent(
            user: userPayload.asModel(),
            cid: cid,
            message: message,
            reaction: reactionPayload.asModel(),
            createdAt: createdAt
        )
    }
    
    private func createReactionDeletedEvent(from payload: EventPayload, cid: ChannelId) -> ReactionDeletedEvent? {
        guard
            let userPayload = payload.user,
            let messagePayload = payload.message,
            let reactionPayload = payload.reaction,
            let createdAt = payload.createdAt,
            let currentUserId = database.writableContext.currentUser?.user.id,
            let channel = try? database.writableContext.channel(cid: cid)?.asModel(),
            let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)
        else { return nil }
        
        return ReactionDeletedEvent(
            user: userPayload.asModel(),
            cid: cid,
            message: message,
            reaction: reactionPayload.asModel(),
            createdAt: createdAt
        )
    }
}

extension EventNotificationCenter {
    func process(_ event: Event, postNotification: Bool = true, completion: (() -> Void)? = nil) {
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
