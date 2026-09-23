//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Handles manual event processing for channels that opt out of middleware processing.
class ManualEventHandler: @unchecked Sendable {
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
        cachedChannels: [ChannelId: ChatChannel] = [:],
        queue: DispatchQueue = DispatchQueue(label: "io.getstream.chat.manualEventHandler", qos: .utility)
    ) {
        self.database = database
        self.cachedChannels = cachedChannels
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
        switch event {
        case let dto as MessageNewEventDTO:
            guard isRegistered(channelId: dto.cid) else { return nil }
            return createMessageNewEvent(from: dto, cid: dto.cid)

        case let dto as MessageUpdatedEventDTO:
            guard isRegistered(channelId: dto.cid) else { return nil }
            return createMessageUpdatedEvent(from: dto, cid: dto.cid)

        case let dto as MessageDeletedEventDTO:
            guard isRegistered(channelId: dto.cid) else { return nil }
            return createMessageDeletedEvent(from: dto, cid: dto.cid)

        case let dto as ReactionNewEventDTO:
            guard isRegistered(channelId: dto.cid) else { return nil }
            return createReactionNewEvent(from: dto, cid: dto.cid)

        case let dto as ReactionUpdatedEventDTO:
            guard isRegistered(channelId: dto.cid) else { return nil }
            return createReactionUpdatedEvent(from: dto, cid: dto.cid)

        case let dto as ReactionDeletedEventDTO:
            guard isRegistered(channelId: dto.cid) else { return nil }
            return createReactionDeletedEvent(from: dto, cid: dto.cid)

        case let dto as TypingEventDTO:
            guard isRegistered(channelId: dto.cid) else { return nil }
            return createTypingEvent(from: dto, cid: dto.cid)

        default:
            return nil
        }
    }

    private func isRegistered(channelId: ChannelId) -> Bool {
        queue.sync { channelIds.contains(channelId) }
    }

    // MARK: - Event Creation Helpers

    private func createMessageNewEvent(from payload: MessageNewEventDTO, cid: ChannelId) -> MessageNewEvent? {
        guard
            let userPayload = payload.user,
            let channel = getLocalChannel(id: cid),
            let currentUserId = database.writableContext.currentUser?.user.id
        else {
            return nil
        }

        let message = payload.message.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)

        return MessageNewEvent(
            user: userPayload.asModel(),
            message: message,
            channel: channel,
            createdAt: payload.createdAt,
            watcherCount: payload.watcherCount,
            unreadCount: payload.totalUnreadCount.map {
                .init(
                    channels: payload.unreadChannels ?? 0,
                    messages: $0,
                    threads: 0
                )
            }
        )
    }

    private func createMessageUpdatedEvent(from payload: MessageUpdatedEventDTO, cid: ChannelId) -> MessageUpdatedEvent? {
        guard
            let userPayload = payload.user,
            let currentUserId = database.writableContext.currentUser?.user.id,
            let channel = getLocalChannel(id: cid)
        else { return nil }

        let message = payload.message.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)

        return MessageUpdatedEvent(
            user: userPayload.asModel(),
            channel: channel,
            message: message,
            createdAt: payload.createdAt
        )
    }

    private func createMessageDeletedEvent(from payload: MessageDeletedEventDTO, cid: ChannelId) -> MessageDeletedEvent? {
        guard
            let currentUserId = database.writableContext.currentUser?.user.id,
            let channel = getLocalChannel(id: cid)
        else { return nil }

        let message = payload.message.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)
        let userPayload = payload.user

        return MessageDeletedEvent(
            user: userPayload?.asModel(),
            channel: channel,
            message: message,
            createdAt: payload.createdAt,
            isHardDelete: payload.hardDelete ?? false,
            deletedForMe: payload.deletedForMe ?? false
        )
    }

    private func createReactionNewEvent(from payload: ReactionNewEventDTO, cid: ChannelId) -> ReactionNewEvent? {
        guard
            let userPayload = payload.user,
            let messagePayload = payload.message,
            let reactionPayload = payload.reaction,
            let currentUserId = database.writableContext.currentUser?.user.id,
            let channel = getLocalChannel(id: cid)
        else { return nil }

        let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)

        return ReactionNewEvent(
            user: userPayload.asModel(),
            cid: cid,
            message: message,
            reaction: reactionPayload.asModel(messageId: messagePayload.id),
            createdAt: payload.createdAt
        )
    }

    private func createReactionUpdatedEvent(from payload: ReactionUpdatedEventDTO, cid: ChannelId) -> ReactionUpdatedEvent? {
        guard
            let userPayload = payload.user,
            let reactionPayload = payload.reaction,
            let currentUserId = database.writableContext.currentUser?.user.id,
            let channel = getLocalChannel(id: cid)
        else { return nil }

        let message = payload.message.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)

        return ReactionUpdatedEvent(
            user: userPayload.asModel(),
            cid: cid,
            message: message,
            reaction: reactionPayload.asModel(messageId: payload.message.id),
            createdAt: payload.createdAt
        )
    }

    private func createTypingEvent(from payload: TypingEventDTO, cid: ChannelId) -> TypingEvent? {
        guard let userPayload = payload.user else { return nil }

        return TypingEvent(
            isTyping: payload.isTyping,
            cid: cid,
            user: userPayload.asModel(),
            memberInfo: payload.member?.asModel(),
            parentId: payload.parentId,
            createdAt: payload.createdAt
        )
    }

    private func createReactionDeletedEvent(from payload: ReactionDeletedEventDTO, cid: ChannelId) -> ReactionDeletedEvent? {
        guard
            let userPayload = payload.user,
            let messagePayload = payload.message,
            let reactionPayload = payload.reaction,
            let currentUserId = database.writableContext.currentUser?.user.id,
            let channel = getLocalChannel(id: cid)
        else { return nil }

        let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)

        return ReactionDeletedEvent(
            user: userPayload.asModel(),
            cid: cid,
            message: message,
            reaction: reactionPayload.asModel(messageId: messagePayload.id),
            createdAt: payload.createdAt
        )
    }

    // This is only needed because some events wrongly require the channel to create them.
    private func getLocalChannel(id: ChannelId) -> ChatChannel? {
        queue.sync {
            if let cachedChannel = cachedChannels[id] {
                return cachedChannel
            }

            let channel = try? database.writableContext.channel(cid: id)?.asModel()
            cachedChannels[id] = channel
            return channel
        }
    }
}
