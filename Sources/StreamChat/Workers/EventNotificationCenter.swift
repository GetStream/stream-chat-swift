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

    private var optimizeLivestreamControllers: Bool

    init(
        database: DatabaseContainer,
        optimizeLivestreamControllers: Bool = false
    ) {
        self.database = database
        self.optimizeLivestreamControllers = optimizeLivestreamControllers
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
            let eventNames = events.map(\.name)
            return "Processing Events: \(eventNames)"
        }
        log.debug(processingEventsDebugMessage(), subsystems: .webSocket)

        let messageIds: [MessageId] = events.compactMap {
            ($0 as? MessageNewEventDTO)?.message.id ?? ($0 as? NotificationMessageNewEventDTO)?.message.id
        }

        var eventsToPost = [Event]()
        var middlewareEvents = [Event]()
        var livestreamEvents = [Event]()

        database.write({ session in
            if self.optimizeLivestreamControllers {
                events
                    .forEach { event in
                        guard let eventDTO = event as? EventDTO else {
                            middlewareEvents.append(event)
                            return
                        }
                        if eventDTO.payload.cid?.rawValue == "messaging:28F0F56D-F" {
                            livestreamEvents.append(event)
                        } else {
                            middlewareEvents.append(event)
                        }
                    }
            } else {
                middlewareEvents = events
            }

            eventsToPost.append(contentsOf: self.forwardLivestreamEvents(livestreamEvents))

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

    private func forwardLivestreamEvents(_ events: [Event]) -> [Event] {
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
                
            case .messageRead:
                return createMessageReadEvent(from: eventPayload, cid: cid)
                
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
    
    private func createChannelFromPayload(_ channelPayload: ChannelDetailPayload, cid: ChannelId) -> ChatChannel {
        ChatChannel(
            cid: cid,
            name: channelPayload.name,
            imageURL: channelPayload.imageURL,
            lastMessageAt: channelPayload.lastMessageAt,
            createdAt: channelPayload.createdAt,
            updatedAt: channelPayload.updatedAt,
            deletedAt: channelPayload.deletedAt,
            truncatedAt: channelPayload.truncatedAt,
            isHidden: false,
            createdBy: channelPayload.createdBy?.asModel(),
            config: channelPayload.config,
            ownCapabilities: Set(channelPayload.ownCapabilities?.compactMap { ChannelCapability(rawValue: $0) } ?? []),
            isFrozen: channelPayload.isFrozen,
            isDisabled: channelPayload.isDisabled,
            isBlocked: channelPayload.isBlocked ?? false,
            lastActiveMembers: [],
            membership: nil,
            currentlyTypingUsers: [],
            lastActiveWatchers: [],
            team: channelPayload.team,
            unreadCount: ChannelUnreadCount(messages: 0, mentions: 0),
            watcherCount: 0,
            memberCount: channelPayload.memberCount,
            reads: [],
            cooldownDuration: channelPayload.cooldownDuration,
            extraData: channelPayload.extraData,
            latestMessages: [],
            lastMessageFromCurrentUser: nil,
            pinnedMessages: [],
            muteDetails: nil,
            previewMessage: nil,
            draftMessage: nil,
            activeLiveLocations: []
        )
    }
    
    private func createMessageNewEvent(from payload: EventPayload, cid: ChannelId) -> MessageNewEvent? {
        guard
            let userPayload = payload.user,
            let messagePayload = payload.message,
            let createdAt = payload.createdAt,
            let channel = try? database.writableContext.channel(cid: cid)?.asModel(),
            let currentUserId = database.writableContext.currentUser?.user.id,
            let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId)
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
            let userPayload = try? payload.value(at: \.user) as UserPayload,
            let messagePayload = try? payload.value(at: \.message) as MessagePayload,
            let createdAt = try? payload.value(at: \.createdAt) as Date,
            let message = messagePayload.asModel(cid: cid),
            let channelPayload = payload.channel
        else { return nil }
        
        let channel = createChannelFromPayload(channelPayload, cid: cid)
        
        return MessageUpdatedEvent(
            user: userPayload.asModel(),
            channel: channel,
            message: message,
            createdAt: createdAt
        )
    }
    
    private func createMessageDeletedEvent(from payload: EventPayload, cid: ChannelId) -> MessageDeletedEvent? {
        guard
            let messagePayload = try? payload.value(at: \.message) as MessagePayload,
            let createdAt = try? payload.value(at: \.createdAt) as Date,
            let message = messagePayload.asModel(cid: cid),
            let channelPayload = payload.channel
        else { return nil }
        
        let userPayload = try? payload.value(at: \.user) as UserPayload?
        let channel = createChannelFromPayload(channelPayload, cid: cid)
        
        return MessageDeletedEvent(
            user: userPayload?.asModel(),
            channel: channel,
            message: message,
            createdAt: createdAt,
            isHardDelete: payload.hardDelete
        )
    }
    
    private func createMessageReadEvent(from payload: EventPayload, cid: ChannelId) -> MessageReadEvent? {
        guard
            let userPayload = try? payload.value(at: \.user) as UserPayload,
            let createdAt = try? payload.value(at: \.createdAt) as Date,
            let channelPayload = payload.channel
        else { return nil }
        
        let channel = createChannelFromPayload(channelPayload, cid: cid)
        
        return MessageReadEvent(
            user: userPayload.asModel(),
            channel: channel,
            thread: nil, // Livestream channels don't support threads typically
            createdAt: createdAt,
            unreadCount: nil // Livestream channels don't track unread counts
        )
    }
    
    private func createReactionNewEvent(from payload: EventPayload, cid: ChannelId) -> ReactionNewEvent? {
        guard
            let userPayload = try? payload.value(at: \.user) as UserPayload,
            let messagePayload = try? payload.value(at: \.message) as MessagePayload,
            let reactionPayload = try? payload.value(at: \.reaction) as MessageReactionPayload,
            let createdAt = try? payload.value(at: \.createdAt) as Date,
            let message = messagePayload.asModel(cid: cid)
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
            let userPayload = try? payload.value(at: \.user) as UserPayload,
            let messagePayload = try? payload.value(at: \.message) as MessagePayload,
            let reactionPayload = try? payload.value(at: \.reaction) as MessageReactionPayload,
            let createdAt = try? payload.value(at: \.createdAt) as Date,
            let message = messagePayload.asModel(cid: cid)
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
            let userPayload = try? payload.value(at: \.user) as UserPayload,
            let messagePayload = try? payload.value(at: \.message) as MessagePayload,
            let reactionPayload = try? payload.value(at: \.reaction) as MessageReactionPayload,
            let createdAt = try? payload.value(at: \.createdAt) as Date,
            let message = messagePayload.asModel(cid: cid)
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
