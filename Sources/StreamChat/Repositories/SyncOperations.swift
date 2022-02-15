//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A class that holds the context for the ongoing operations during the sync process
class SyncContext {
    var lastConnectionDate: Date?
    var lastPendingConnectionDate: Date?
    var localChannelIds: [ChannelId] = []
    var synchedChannelIds: Set<ChannelId> = Set()
    var watchedChannelIds: Set<ChannelId> = Set()
}

private let syncOperationsMaximumRetries = 2

class GetChannelIdsOperation: AsyncOperation {
    init(database: DatabaseContainer, context: SyncContext) {
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
                context.localChannelIds = cids
                done(.continue)
            }
        }
    }
}

class GetPendingConnectionDateOperation: AsyncOperation {
    init(database: DatabaseContainer, context: SyncContext) {
        super.init(maxRetries: syncOperationsMaximumRetries) { [weak database] _, done in
            database?.backgroundReadOnlyContext.perform {
                context.lastPendingConnectionDate = database?.backgroundReadOnlyContext.currentUser?.lastPendingConnectionDate
                done(.continue)
            }
        }
    }
}

class SyncEventsOperation: AsyncOperation {
    init(database: DatabaseContainer, syncRepository: SyncRepository, context: SyncContext) {
        super.init(maxRetries: syncOperationsMaximumRetries) { [weak database, weak syncRepository] _, done in
            log.info(
                "1. Call `/sync` endpoint and get missing events for all locally existed channels",
                subsystems: .offlineSupport
            )
            guard let lastPendingConnectionDate = context.lastPendingConnectionDate else {
                done(.continue)
                return
            }

            syncRepository?.syncMissingEvents(
                using: lastPendingConnectionDate,
                channelIds: context.localChannelIds,
                bumpLastSync: false,
                isRecoveryRequest: true
            ) { result in
                switch result {
                case let .success(channelIds):
                    context.synchedChannelIds = Set(channelIds)
                    // As per our sync logic, we should keep the last connection date.
                    database?.write { session in
                        session.currentUser?.lastPendingConnectionDate = context.lastConnectionDate
                    } completion: { _ in done(.continue) }
                case let .failure(error):
                    context.synchedChannelIds = Set([])
                    done(error.shouldRetry ? .retry : .continue)
                }
            }
        }
    }
}

class WatchChannelOperation: AsyncOperation {
    init(controller: ChatChannelController, context: SyncContext) {
        super.init(maxRetries: syncOperationsMaximumRetries) { [weak controller] _, done in
            guard let controller = controller, controller.isAvailableOnRemote else {
                done(.continue)
                return
            }

            // Reset only if it needs recovery
            if let cid = controller.cid, context.synchedChannelIds.contains(cid) {
                done(.continue)
                return
            }

            let cidString = (controller.cid?.rawValue ?? "unknown")
            log.info("2. Watching active channel \(cidString)", subsystems: .offlineSupport)
            controller.watchActiveChannel { error in
                if let cid = controller.cid, error == nil {
                    log.info("Successfully watched active channel \(cidString)", subsystems: .offlineSupport)
                    context.watchedChannelIds.insert(cid)
                    done(.continue)
                } else {
                    let errorMessage = error?.localizedDescription ?? "missing cid"
                    log.error("Failed watching active channel \(cidString): \(errorMessage)", subsystems: .offlineSupport)
                    done(.retry)
                }
            }
        }
    }
}

class RefetchChannelListQueryOperation: AsyncOperation {
    init(controller: ChatChannelListController, channelRepository: ChannelListUpdater, context: SyncContext) {
        super.init(maxRetries: syncOperationsMaximumRetries) { [weak controller] _, done in
            guard let controller = controller, controller.isAvailableOnRemote else {
                done(.continue)
                return
            }

            log.info("3 & 4. Refetching channel lists queries & Cleaning up local message history", subsystems: .offlineSupport)
            channelRepository.resetChannelsQuery(
                for: controller.query,
                watchedChannelIds: context.watchedChannelIds,
                synchedChannelIds: context.synchedChannelIds
            ) { result in
                switch result {
                case let .success(channels):
                    log.info("Successfully refetched query for \(controller.query.debugDescription)", subsystems: .offlineSupport)
                    let queryChannelIds = channels.map(\.cid)
                    context.synchedChannelIds = context.synchedChannelIds.union(queryChannelIds)
                    done(.continue)
                case let .failure(error):
                    log.error(
                        "Failed refetching query for \(controller.query.debugDescription): \(error)",
                        subsystems: .offlineSupport
                    )
                    done(.retry)
                }
            }
        }
    }
}

class ExecutePendingOfflineActions: AsyncOperation {
    init(offlineRequestsRepository: OfflineRequestsRepository) {
        super.init(maxRetries: syncOperationsMaximumRetries) { [weak offlineRequestsRepository] _, done in
            offlineRequestsRepository?.runQueuedRequests {
                done(.continue)
            }
        }
    }
}
