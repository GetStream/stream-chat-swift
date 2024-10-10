//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A final class that holds the context for the ongoing operations during the sync process
final class SyncContext {
    let lastSyncAt: Date
    var localChannelIds: Set<ChannelId> = Set()
    var synchedChannelIds: Set<ChannelId> = Set()
    var watchedAndSynchedChannelIds: Set<ChannelId> = Set()
    var unwantedChannelIds: Set<ChannelId> = Set()

    init(lastSyncAt: Date) {
        self.lastSyncAt = lastSyncAt
    }
}

private let syncOperationsMaximumRetries = 2

final class ActiveChannelIdsOperation: AsyncOperation, @unchecked Sendable {
    init(
        syncRepository: SyncRepository,
        context: SyncContext
    ) {
        super.init(maxRetries: syncOperationsMaximumRetries) { [weak syncRepository] _, done in
            guard let syncRepository else {
                done(.continue)
                return
            }
            
            let completion: () -> Void = {
                context.localChannelIds = Set(context.localChannelIds)
                log.info("Found \(context.localChannelIds.count) active channels", subsystems: .offlineSupport)
                done(.continue)
            }
            
            context.localChannelIds.formUnion(syncRepository.activeChannelControllers.allObjects.compactMap(\.cid))
            context.localChannelIds.formUnion(
                syncRepository.activeChannelListControllers.allObjects
                    .map(\.channels)
                    .flatMap { $0 }
                    .map(\.cid)
            )
            
            let activeChats = syncRepository.activeChats.allObjects
            let activeChannelLists = syncRepository.activeChannelLists.allObjects
            if activeChats.isEmpty, activeChannelLists.isEmpty {
                completion()
            } else {
                // Main actor requirement
                DispatchQueue.main.async {
                    context.localChannelIds.formUnion(syncRepository.activeChats.allObjects.compactMap { try? $0.cid })
                    context.localChannelIds.formUnion(
                        syncRepository.activeChannelLists.allObjects
                            .map(\.state.channels)
                            .flatMap { $0 }
                            .map(\.cid)
                    )
                    completion()
                }
            }
        }
    }
}

final class RefreshChannelListOperation: AsyncOperation, @unchecked Sendable {
    init(controller: ChatChannelListController, context: SyncContext) {
        super.init(maxRetries: syncOperationsMaximumRetries) { [weak controller] _, done in
            guard let controller = controller, controller.canBeRecovered else {
                done(.continue)
                return
            }
            controller.refreshLoadedChannels { result in
                switch result {
                case .success(let channelIds):
                    log.debug("Synced \(channelIds.count) channels in a channel list controller (\(controller.query.filter)", subsystems: .offlineSupport)
                    context.synchedChannelIds.formUnion(channelIds)
                    done(.continue)
                case .failure(let error):
                    log.error("Failed refreshing channel list controller (\(controller.query.filter) with error \(error)", subsystems: .offlineSupport)
                    done(.retry)
                }
            }
        }
    }
    
    init(channelList: ChannelList, context: SyncContext) {
        super.init(maxRetries: syncOperationsMaximumRetries) { [weak channelList] _, done in
            guard let channelList else {
                done(.continue)
                return
            }
            Task {
                do {
                    let channelIds = try await channelList.refreshLoadedChannels()
                    log.debug("Synced \(channelIds.count) channels in a channel list (\(channelList.query.filter)", subsystems: .offlineSupport)
                    context.synchedChannelIds.formUnion(channelIds)
                    done(.continue)
                } catch {
                    log.error("Failed refreshing channel list (\(channelList.query.filter) with error \(error)", subsystems: .offlineSupport)
                    done(.retry)
                }
            }
        }
    }
}

final class GetChannelIdsOperation: AsyncOperation, @unchecked Sendable {
    init(database: DatabaseContainer, context: SyncContext, activeChannelIds: [ChannelId]) {
        super.init(maxRetries: syncOperationsMaximumRetries) { [weak database] _, done in
            guard let database = database else {
                done(.continue)
                return
            }
            database.backgroundReadOnlyContext.perform {
                let cids = database.backgroundReadOnlyContext.loadAllChannelListQueries()
                    .flatMap(\.channels)
                    .compactMap { try? ChannelId(cid: $0.cid) }
                log.info("0. Retrieved channels from existing queries from DB. Count \(cids.count)", subsystems: .offlineSupport)
                context.localChannelIds = Set(cids + activeChannelIds)
                done(.continue)
            }
        }
    }
}

final class SyncEventsOperation: AsyncOperation, @unchecked Sendable {
    init(syncRepository: SyncRepository, context: SyncContext, recovery: Bool) {
        super.init(maxRetries: syncOperationsMaximumRetries) { [weak syncRepository] _, done in
            log.info(
                "1. Call `/sync` endpoint and get missing events for all locally existed channels",
                subsystems: .offlineSupport
            )

            let channelIds = Set(context.localChannelIds).subtracting(context.synchedChannelIds)
            guard !channelIds.isEmpty else {
                done(.continue)
                return
            }
            
            syncRepository?.syncChannelsEvents(
                channelIds: Array(channelIds),
                lastSyncAt: context.lastSyncAt,
                isRecovery: recovery
            ) { result in
                switch result {
                case let .success(channelIds):
                    context.synchedChannelIds.formUnion(channelIds)
                    done(.continue)
                case let .failure(error):
                    done(error.shouldRetry ? .retry : .continue)
                }
            }
        }
    }
}

final class WatchChannelOperation: AsyncOperation, @unchecked Sendable {
    init(controller: ChatChannelController, context: SyncContext, recovery: Bool) {
        super.init(maxRetries: syncOperationsMaximumRetries) { [weak controller] _, done in
            guard let controller = controller, controller.canBeRecovered else {
                done(.continue)
                return
            }

            let cidString = (controller.cid?.rawValue ?? "unknown")
            log.info("Watching active channel \(cidString)", subsystems: .offlineSupport)
            controller.recoverWatchedChannel(recovery: recovery) { error in
                if let cid = controller.cid, error == nil {
                    log.info("Successfully watched active channel \(cidString)", subsystems: .offlineSupport)
                    context.watchedAndSynchedChannelIds.insert(cid)
                    done(.continue)
                } else {
                    let errorMessage = error?.localizedDescription ?? "missing cid"
                    log.error("Failed watching active channel \(cidString): \(errorMessage)", subsystems: .offlineSupport)
                    done(.retry)
                }
            }
        }
    }
    
    init(chat: Chat, context: SyncContext) {
        super.init(maxRetries: syncOperationsMaximumRetries) { [weak chat] _, done in
            guard let chat else {
                done(.continue)
                return
            }
            Task {
                guard await chat.state.channelQuery.options.contains(.watch) else {
                    done(.continue)
                    return
                }
                do {
                    let cid = try await chat.cid
                    log.info("Watching active chat \(cid.rawValue)", subsystems: .offlineSupport)
                    try await chat.watch()
                    context.watchedAndSynchedChannelIds.insert(cid)
                    log.info("Successfully watched active chat \(cid.rawValue)", subsystems: .offlineSupport)
                    done(.continue)
                } catch {
                    log.error("Failed watching active chat with error \(error.localizedDescription)", subsystems: .offlineSupport)
                    done(.retry)
                }
            }
        }
    }
}

final class RefetchChannelListQueryOperation: AsyncOperation, @unchecked Sendable {
    init(controller: ChatChannelListController, context: SyncContext) {
        super.init(maxRetries: syncOperationsMaximumRetries) { [weak controller] _, done in
            guard let controller = controller, controller.canBeRecovered else {
                done(.continue)
                return
            }

            let query = controller.query

            log.info("3 & 4. Refetching channel lists queries & Cleaning up local message history", subsystems: .offlineSupport)
            controller.resetQuery(
                watchedAndSynchedChannelIds: context.watchedAndSynchedChannelIds,
                synchedChannelIds: context.synchedChannelIds
            ) { result in
                Self.handleResult(result, query: query, context: context, done: done)
            }
        }
    }
    
    init(query: ChannelListQuery, channelListUpdater: ChannelListUpdater, context: SyncContext) {
        super.init(maxRetries: syncOperationsMaximumRetries) { _, done in
            log.info("3 & 4. Refetching channel lists queries (step 2)", subsystems: .offlineSupport)
            channelListUpdater.resetChannelsQuery(
                for: query,
                pageSize: query.pagination.pageSize,
                watchedAndSynchedChannelIds: context.watchedAndSynchedChannelIds,
                synchedChannelIds: context.synchedChannelIds
            ) { result in
                Self.handleResult(result, query: query, context: context, done: done)
            }
        }
    }
    
    private static func handleResult(
        _ result: Result<(synchedAndWatched: [ChatChannel], unwanted: Set<ChannelId>), any Error>,
        query: ChannelListQuery,
        context: SyncContext,
        done: (AsyncOperation.Output) -> Void
    ) {
        switch result {
        case let .success((watchedChannels, unwantedCids)):
            log.info("Successfully refetched query for \(query.debugDescription)", subsystems: .offlineSupport)
            let queryChannelIds = watchedChannels.map(\.cid)
            context.watchedAndSynchedChannelIds.formUnion(queryChannelIds)
            context.unwantedChannelIds.formUnion(unwantedCids)
            done(.continue)
        case let .failure(error):
            log.error(
                "Failed refetching query for \(query.debugDescription): \(error)",
                subsystems: .offlineSupport
            )
            done(.retry)
        }
    }
}

final class DeleteUnwantedChannelsOperation: AsyncOperation, @unchecked Sendable {
    init(database: DatabaseContainer, context: SyncContext) {
        super.init(maxRetries: syncOperationsMaximumRetries) { [weak database] _, done in
            log.info("4. Clean up unwanted channels", subsystems: .offlineSupport)

            guard let database = database, !context.unwantedChannelIds.isEmpty else {
                done(.continue)
                return
            }

            // We are going to remove those channels that are not present in remote queries, and that have not
            // been watched.
            database.write { session in
                // We remove watchedAndSynched from unwantedChannels because it might happen that a channel marked
                // as unwanted in one query, might still be needed in another query (scenario where multiple queries
                // are active at the same time).
                let idsToRemove = context.unwantedChannelIds.subtracting(context.watchedAndSynchedChannelIds)
                session.removeChannels(cids: idsToRemove)
            } completion: { error in
                if let error = error {
                    log.error(
                        "Failed removing unwanted channels: \(error)",
                        subsystems: .offlineSupport
                    )
                    done(.retry)
                } else {
                    done(.continue)
                }
            }
        }
    }
}

final class ExecutePendingOfflineActions: AsyncOperation, @unchecked Sendable {
    init(offlineRequestsRepository: OfflineRequestsRepository) {
        super.init(maxRetries: syncOperationsMaximumRetries) { [weak offlineRequestsRepository] _, done in
            log.info("Running offline actions requests", subsystems: .offlineSupport)
            offlineRequestsRepository?.runQueuedRequests {
                done(.continue)
            }
        }
    }
}
