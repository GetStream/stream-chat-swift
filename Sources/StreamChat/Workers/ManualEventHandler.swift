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
            guard let cid = parseCID(dto.cid), isRegistered(channelId: cid) else { return nil }
            return createMessageNewEvent(from: dto, cid: cid)

        case let dto as MessageUpdatedEventDTO:
            guard let cid = parseCID(dto.cid), isRegistered(channelId: cid) else { return nil }
            return createMessageUpdatedEvent(from: dto, cid: cid)

        case let dto as MessageDeletedEventDTO:
            guard let cid = parseCID(dto.cid), isRegistered(channelId: cid) else { return nil }
            return createMessageDeletedEvent(from: dto, cid: cid)

        case let dto as ReactionNewEventDTO:
            guard let cid = parseCID(dto.cid), isRegistered(channelId: cid) else { return nil }
            return createReactionNewEvent(from: dto, cid: cid)

        case let dto as ReactionUpdatedEventDTO:
            guard let cid = parseCID(dto.cid), isRegistered(channelId: cid) else { return nil }
            return createReactionUpdatedEvent(from: dto, cid: cid)

        case let dto as ReactionDeletedEventDTO:
            guard let cid = parseCID(dto.cid), isRegistered(channelId: cid) else { return nil }
            return createReactionDeletedEvent(from: dto, cid: cid)

        case let dto as TypingStartEventDTO:
            guard let cid = parseCID(dto.cid), isRegistered(channelId: cid) else { return nil }
            return createTypingEvent(isTyping: true, userFields: dto.user, parentId: dto.parentId, createdAt: dto.createdAt, cid: cid)

        case let dto as TypingStopEventDTO:
            guard let cid = parseCID(dto.cid), isRegistered(channelId: cid) else { return nil }
            return createTypingEvent(isTyping: false, userFields: dto.user, parentId: dto.parentId, createdAt: dto.createdAt, cid: cid)

        default:
            return nil
        }
    }

    private func parseCID(_ cid: String?) -> ChannelId? {
        cid.flatMap { try? ChannelId(cid: $0) }
    }

    private func isRegistered(channelId: ChannelId) -> Bool {
        queue.sync { channelIds.contains(channelId) }
    }

    // MARK: - Event Creation Helpers

    private func createMessageNewEvent(from dto: MessageNewEventDTO, cid: ChannelId) -> MessageNewEvent? {
        guard
            let userFields = dto.user,
            let channel = getLocalChannel(id: cid),
            let currentUserId = database.writableContext.currentUser?.user.id
        else {
            return nil
        }

        let message = dto.message.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)

        return MessageNewEvent(
            user: userFields.asModel(),
            message: message,
            channel: channel,
            createdAt: dto.createdAt,
            watcherCount: dto.watcherCount,
            unreadCount: dto.unreadCount.map { .init(channels: 0, messages: $0, threads: 0) }
        )
    }

    private func createMessageUpdatedEvent(from dto: MessageUpdatedEventDTO, cid: ChannelId) -> MessageUpdatedEvent? {
        guard
            let userFields = dto.user,
            let currentUserId = database.writableContext.currentUser?.user.id,
            let channel = getLocalChannel(id: cid)
        else { return nil }

        let message = dto.message.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)

        return MessageUpdatedEvent(
            user: userFields.asModel(),
            channel: channel,
            message: message,
            createdAt: dto.createdAt
        )
    }

    private func createMessageDeletedEvent(from dto: MessageDeletedEventDTO, cid: ChannelId) -> MessageDeletedEvent? {
        guard
            let currentUserId = database.writableContext.currentUser?.user.id,
            let channel = getLocalChannel(id: cid)
        else { return nil }

        let message = dto.message.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)

        return MessageDeletedEvent(
            user: dto.user.map { $0.asModel() },
            channel: channel,
            message: message,
            createdAt: dto.createdAt,
            isHardDelete: dto.hardDelete ?? false,
            deletedForMe: dto.deletedForMe ?? false
        )
    }

    private func createReactionNewEvent(from dto: ReactionNewEventDTO, cid: ChannelId) -> ReactionNewEvent? {
        guard
            let userFields = dto.user,
            let messagePayload = dto.message,
            let reactionPayload = dto.reaction,
            let currentUserId = database.writableContext.currentUser?.user.id,
            let channel = getLocalChannel(id: cid)
        else { return nil }

        let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)

        return ReactionNewEvent(
            user: userFields.asModel(),
            cid: cid,
            message: message,
            reaction: reactionPayload.asModel(messageId: messagePayload.id),
            createdAt: dto.createdAt
        )
    }

    private func createReactionUpdatedEvent(from dto: ReactionUpdatedEventDTO, cid: ChannelId) -> ReactionUpdatedEvent? {
        guard
            let userFields = dto.user,
            let reactionPayload = dto.reaction,
            let currentUserId = database.writableContext.currentUser?.user.id,
            let channel = getLocalChannel(id: cid)
        else { return nil }

        let message = dto.message.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)

        return ReactionUpdatedEvent(
            user: userFields.asModel(),
            cid: cid,
            message: message,
            reaction: reactionPayload.asModel(messageId: dto.message.id),
            createdAt: dto.createdAt
        )
    }

    private func createTypingEvent(
        isTyping: Bool,
        userFields: UserResponseCommonFields?,
        parentId: MessageId?,
        createdAt: Date,
        cid: ChannelId
    ) -> TypingEvent? {
        guard let userFields else { return nil }

        return TypingEvent(
            isTyping: isTyping,
            cid: cid,
            user: userFields.asModel(),
            parentId: parentId,
            createdAt: createdAt
        )
    }

    private func createReactionDeletedEvent(from dto: ReactionDeletedEventDTO, cid: ChannelId) -> ReactionDeletedEvent? {
        guard
            let userFields = dto.user,
            let messagePayload = dto.message,
            let reactionPayload = dto.reaction,
            let currentUserId = database.writableContext.currentUser?.user.id,
            let channel = getLocalChannel(id: cid)
        else { return nil }

        let message = messagePayload.asModel(cid: cid, currentUserId: currentUserId, channelReads: channel.reads)

        return ReactionDeletedEvent(
            user: userFields.asModel(),
            cid: cid,
            message: message,
            reaction: reactionPayload.asModel(messageId: messagePayload.id),
            createdAt: dto.createdAt
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
