//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Handles manual event processing for channels that opt out of middleware processing.
class ManualEventHandler {
    /// The database used when evaluating events.
    private let database: DatabaseContainer

    /// The queue for thread-safe operations.
    private let queue: DispatchQueue

    // The channels for which events will not be processed by the middlewares.
    private var channelIds: Set<ChannelId> = []

    // Some events require the chat channel data, so we need to fetch it from local DB.
    // We try to only do this once, to avoid unnecessary DB fetches.
    private var cachedChannels: [ChannelId: ChatChannel] = [:]

    init(
        database: DatabaseContainer,
        queue: DispatchQueue = DispatchQueue(label: "io.getstream.chat.manualEventHandler", qos: .background)
    ) {
        self.database = database
        self.queue = queue
    }

    /// Registers a channel for manual event handling.
    ///
    /// The middleware's will not process events for this channel.
    func register(channelId: ChannelId) {
        queue.async { [weak self] in
            self?.channelIds.insert(channelId)
        }
    }

    /// Unregister a channel for manual event handling.
    func unregister(channelId: ChannelId) {
        queue.async { [weak self] in
            self?.channelIds.remove(channelId)
            self?.cachedChannels.removeValue(forKey: channelId)
        }
    }

    /// Converts a manual event to its domain representation.
    func handle(_ event: Event) -> Event? {
        guard let eventDTO = event as? EventDTO else {
            return nil
        }

        let eventPayload = eventDTO.payload

        guard let cid = eventPayload.cid else {
            return nil
        }

        guard isRegistered(channelId: cid) else {
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

        case .channelUpdated:
            return createChannelUpdatedEvent(from: eventPayload, cid: cid)

        default:
            return nil
        }
    }

    private func isRegistered(channelId: ChannelId) -> Bool {
        queue.sync { channelIds.contains(channelId) }
    }

    // MARK: - Event Creation Helpers

    private func createMessageNewEvent(from payload: EventPayload, cid: ChannelId) -> MessageNewEvent? {
        guard
            let userPayload = payload.user,
            let messagePayload = payload.message,
            let createdAt = payload.createdAt,
            let channel = getLocalChannel(id: cid),
            let currentUserId = database.writableContext.currentUser?.user.id
        else {
            return nil
        }

        let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)

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
            let channel = getLocalChannel(id: cid)
        else { return nil }

        let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)

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
            let channel = getLocalChannel(id: cid)
        else { return nil }

        let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)
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
            let channel = getLocalChannel(id: cid)
        else { return nil }

        let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)

        return ReactionNewEvent(
            user: userPayload.asModel(),
            cid: cid,
            message: message,
            reaction: reactionPayload.asModel(messageId: messagePayload.id),
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
            let channel = getLocalChannel(id: cid)
        else { return nil }

        let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)

        return ReactionUpdatedEvent(
            user: userPayload.asModel(),
            cid: cid,
            message: message,
            reaction: reactionPayload.asModel(messageId: messagePayload.id),
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
            let channel = getLocalChannel(id: cid)
        else { return nil }

        let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)

        return ReactionDeletedEvent(
            user: userPayload.asModel(),
            cid: cid,
            message: message,
            reaction: reactionPayload.asModel(messageId: messagePayload.id),
            createdAt: createdAt
        )
    }

    private func createChannelUpdatedEvent(from payload: EventPayload, cid: ChannelId) -> ChannelUpdatedEvent? {
        guard
            let createdAt = payload.createdAt,
            let channel = payload.channel?.asModel()
        else { return nil }

        let currentUserId = database.writableContext.currentUser?.user.id
        let channelReads = channel.reads

        return ChannelUpdatedEvent(
            channel: channel,
            user: payload.user?.asModel(),
            message: payload.message?.asModel(cid: cid, currentUserId: currentUserId, channelReads: channelReads),
            createdAt: createdAt
        )
    }

    // This is only needed because some events wrongly require the channel to create them.
    private func getLocalChannel(id: ChannelId) -> ChatChannel? {
        if let cachedChannel = cachedChannels[id] {
            return cachedChannel
        }

        let channel = try? database.writableContext.channel(cid: id)?.asModel()
        cachedChannels[id] = channel
        return channel
    }
}
