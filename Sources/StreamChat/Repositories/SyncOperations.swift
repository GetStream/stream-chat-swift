//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
                channelIds: Array(channelIds.prefix(100)),
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

    init(livestreamController: LivestreamChannelController, context: SyncContext, recovery: Bool) {
        super.init(maxRetries: syncOperationsMaximumRetries) { [weak livestreamController] _, done in
            guard let controller = livestreamController else {
                done(.continue)
                return
            }

            let cidString = (controller.cid?.rawValue ?? "unknown")
            log.info("Watching active channel \(cidString)", subsystems: .offlineSupport)
            controller.startWatching(isInRecoveryMode: recovery) { error in
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
