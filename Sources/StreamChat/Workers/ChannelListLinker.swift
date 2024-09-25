//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Inserts or removes channels from the currently loaded channel list based on web-socket events.
///
/// Requires either `filter` or `isChannelAutomaticFilteringEnabled` to be set.
/// - Channels are inserted (linked) only when they would end up on the currently loaded pages.
/// - Channels are removed (unlinked) when not on the currently loaded pages.
final class ChannelListLinker {
    private let clientConfig: ChatClientConfig
    private let databaseContainer: DatabaseContainer
    private var eventObservers = [EventObserver]()
    private let filter: ((ChatChannel) -> Bool)?
    private let loadedChannels: () -> StreamCollection<ChatChannel>
    private let query: ChannelListQuery
    private let worker: ChannelListUpdater
    
    init(
        query: ChannelListQuery,
        filter: ((ChatChannel) -> Bool)?,
        loadedChannels: @escaping () -> StreamCollection<ChatChannel>,
        clientConfig: ChatClientConfig,
        databaseContainer: DatabaseContainer,
        worker: ChannelListUpdater
    ) {
        self.clientConfig = clientConfig
        self.databaseContainer = databaseContainer
        self.filter = filter
        self.loadedChannels = loadedChannels
        self.query = query
        self.worker = worker
    }
    
    func start(with nc: EventNotificationCenter) {
        guard eventObservers.isEmpty else { return }
        eventObservers = [
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? NotificationAddedToChannelEvent },
                callback: { [weak self] event in self?.handleChannel(event.channel) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? MessageNewEvent },
                callback: { [weak self] event in self?.handleChannel(event.channel) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? NotificationMessageNewEvent },
                callback: { [weak self] event in self?.handleChannel(event.channel) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? ChannelUpdatedEvent },
                callback: { [weak self] event in self?.handleChannel(event.channel) }
            ),
            EventObserver(
                notificationCenter: nc,
                transform: { $0 as? ChannelVisibleEvent },
                callback: { [weak self, databaseContainer] event in
                    let context = databaseContainer.backgroundReadOnlyContext
                    context.perform {
                        guard let channel = try? context.channel(cid: event.cid)?.asModel() else { return }
                        self?.handleChannel(channel)
                    }
                }
            )
        ]
    }
    
    enum LinkingAction {
        case link, unlink, none
    }
    
    private func handleChannel(_ channel: ChatChannel) {
        let action = linkingActionForChannel(channel)
        switch action {
        case .link:
            worker.link(channel: channel, with: query) { [worker] error in
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
        case .unlink:
            worker.unlink(channel: channel, with: query) { error in
                guard let error = error else { return }
                log.error(error)
            }
        case .none:
            break
        }
    }
    
    private func linkingActionForChannel(_ channel: ChatChannel) -> LinkingAction {
        // Linking/unlinking can only happen when either runtime filter is set or `isChannelAutomaticFilteringEnabled` is true
        // In other cases the channel list should not be changed.
        guard filter != nil || clientConfig.isChannelAutomaticFilteringEnabled else { return .none }
        let belongsToQuery: Bool = {
            if let filter = filter {
                return filter(channel)
            }
            // When auto-filtering is enabled the channel will appear or not automatically if the
            // query matches the DB Predicate. So here we default to saying it always belong to the current query.
            return clientConfig.isChannelAutomaticFilteringEnabled
        }()
        
        let loadedSortedChannels = loadedChannels()
        if loadedSortedChannels.contains(where: { $0.cid == channel.cid }) {
            return belongsToQuery ? .none : .unlink
        } else {
            // If the channel would be appended, consider it to be part of an old page.
            if let last = loadedSortedChannels.last {
                let sort: [Sorting<ChannelListSortingKey>] = query.sort.isEmpty ? [Sorting(key: ChannelListSortingKey.default)] : query.sort
                let preceedsLastLoaded = [last, channel]
                    .sorted(using: sort.compactMap(\.sortValue))
                    .first?.cid == channel.cid
                if preceedsLastLoaded || loadedSortedChannels.count < query.pagination.pageSize {
                    return belongsToQuery ? .link : .none
                } else {
                    return .none
                }
            } else {
                return belongsToQuery ? .link : .none
            }
        }
    }
}
