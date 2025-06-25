//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// When we receive events, we need to check if a channel should be added or removed from
/// the current query depending on the following events:
/// - Channel created: We analyse if the channel should be added to the current query.
/// - New message sent: This means the channel will reorder and appear on first position,
///   so we also analyse if it should be added to the current query.
/// - Channel is updated: We only check if we should remove it from the current query.
///   We don't try to add it to the current query to not mess with pagination.
final class ChannelListLinker: Sendable {
    private let clientConfig: ChatClientConfig
    private let databaseContainer: DatabaseContainer
    nonisolated(unsafe) private var eventObservers = [EventObserver]()
    private let filter: (@Sendable(ChatChannel) -> Bool)?
    private let query: ChannelListQuery
    private let worker: ChannelListUpdater
    
    init(
        query: ChannelListQuery,
        filter: (@Sendable(ChatChannel) -> Bool)?,
        clientConfig: ChatClientConfig,
        databaseContainer: DatabaseContainer,
        worker: ChannelListUpdater
    ) {
        self.clientConfig = clientConfig
        self.databaseContainer = databaseContainer
        self.filter = filter
        self.query = query
        self.worker = worker
    }
    
    func start(with nc: EventNotificationCenter) {
        guard eventObservers.isEmpty else { return }
        eventObservers = [
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? NotificationAddedToChannelEvent }
            ) { [weak self] event in self?.linkChannelIfNeeded(event.channel) },
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? MessageNewEvent },
                callback: { [weak self] event in self?.linkChannelIfNeeded(event.channel) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? NotificationMessageNewEvent },
                callback: { [weak self] event in self?.linkChannelIfNeeded(event.channel) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? ChannelUpdatedEvent },
                callback: { [weak self] event in self?.unlinkChannelIfNeeded(event.channel) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? ChannelVisibleEvent },
                callback: { [weak self, databaseContainer] event in
                    let context = databaseContainer.backgroundReadOnlyContext
                    context.perform {
                        guard let channel = try? context.channel(cid: event.cid)?.asModel() else { return }
                        self?.linkChannelIfNeeded(channel)
                    }
                }
            )
        ]
    }

    private func isInChannelList(_ channel: ChatChannel, completion: @escaping (Bool) -> Void) {
        let context = databaseContainer.backgroundReadOnlyContext
        context.performAndWait { [weak self] in
            guard let self else { return }
            if let (channelDTO, queryDTO) = context.getChannelWithQuery(cid: channel.cid, query: self.query) {
                let isPresent = queryDTO.channels.contains(channelDTO)
                completion(isPresent)
            } else {
                completion(false)
            }
        }
    }
    
    /// Handles if a channel should be linked to the current query or not.
    private func linkChannelIfNeeded(_ channel: ChatChannel) {
        guard shouldChannelBelongToCurrentQuery(channel) else { return }
        isInChannelList(channel) { [worker, query] exists in
            guard !exists else { return }
            worker.link(channel: channel, with: query) { error in
                if let error = error {
                    log.error(error)
                    return
                }
                worker.startWatchingChannels(withIds: [channel.cid]) { error in
                    guard let error = error else { return }
                    log.warning(
                        "Failed to start watching linked channel: \(channel.cid), error: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    /// Handles if a channel should be unlinked from the current query or not.
    private func unlinkChannelIfNeeded(_ channel: ChatChannel) {
        guard !shouldChannelBelongToCurrentQuery(channel) else { return }
        isInChannelList(channel) { [worker, query] exists in
            guard exists else { return }
            worker.unlink(channel: channel, with: query)
        }
    }

    /// Checks if the given channel should belong to the current query or not.
    private func shouldChannelBelongToCurrentQuery(_ channel: ChatChannel) -> Bool {
        if let filter = filter {
            return filter(channel)
        }

        if clientConfig.isChannelAutomaticFilteringEnabled {
            // When auto-filtering is enabled the channel will appear or not automatically if the
            // query matches the DB Predicate. So here we default to saying it always belong to the current query.
            return true
        }

        return false
    }
}
