//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

enum SyncError: Error {
    case localStorageDisabled
    case noNeedToSync
    case tooManyEvents(Error)
    case syncEndpointFailed(Error)
    case resettingQueryFailed(Error)
    case watchingActiveChannelFailed(Error)
    case missingChannelId
    case couldNotUpdateUserValue(Error)

    var shouldRetry: Bool {
        switch self {
        case .localStorageDisabled, .noNeedToSync, .tooManyEvents, .couldNotUpdateUserValue:
            return false
        case .syncEndpointFailed, .resettingQueryFailed, .watchingActiveChannelFailed, .missingChannelId:
            return true
        }
    }
}

/// This class is in charge of the synchronization of our local storage with the remote.
/// When executing a sync, it will remove outdated elements, and will refresh the content to always show the latest data.
class SyncRepository {
    /// Do not call the sync endpoint more than once every six seconds
    let syncCooldown: TimeInterval = 6.0
    /// Maximum number of retries for each operation step.
    let maxRetriesCount = 2
    let config: ChatClientConfig
    let activeChannelControllers: NSHashTable<ChatChannelController>
    let activeChannelListControllers: NSHashTable<ChatChannelListController>
    let channelRepository: ChannelListUpdater
    let eventNotificationCenter: EventNotificationCenter
    let database: DatabaseContainer
    let apiClient: APIClient
    private var lastConnection: Date?

    private lazy var operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.name = "com.stream.sync-repository"
        return operationQueue
    }()

    init(
        config: ChatClientConfig,
        activeChannelControllers: NSHashTable<ChatChannelController>,
        activeChannelListControllers: NSHashTable<ChatChannelListController>,
        channelRepository: ChannelListUpdater,
        eventNotificationCenter: EventNotificationCenter,
        database: DatabaseContainer,
        apiClient: APIClient
    ) {
        self.config = config
        self.activeChannelControllers = activeChannelControllers
        self.activeChannelListControllers = activeChannelListControllers
        self.channelRepository = channelRepository
        self.eventNotificationCenter = eventNotificationCenter
        self.database = database
        self.apiClient = apiClient
    }

    /// Syncs the local state with the server to make sure the local database is up to date.
    /// It features queuing, serialization and retries
    ///
    /// [Sync and watch channels](https://www.notion.so/2-Sync-and-watch-channels-ac44feb55de3482f8f0f99e100ca40c6)
    /// 1. Call `/sync` endpoint and get missing events for all locally existed channels
    /// 2. Start watching open channels
    /// 3. Refetch channel lists queries, link only what backend returns (the 1st page)
    /// 4. Clean up local message history for channels that are outdated/will get outdated
    /// 5. Bump the last sync timestamp
    ///
    /// - Parameter completion: A block that will get executed upon completion of the synchronization
    func syncLocalState(completion: @escaping () -> Void) {
        guard config.isLocalStorageEnabled else {
            completion()
            return
        }

        operationQueue.cancelAllOperations()

        log.info("Starting to recover offline state", subsystems: .offlineSupport)
        var operations: [Operation] = []

        // 0. We get the existing channelIds
        var preSyncChannelIds: [ChannelId] = []
        operations.append(AsyncOperation { [weak self] done in
            log.info("0. We get the existing channelIds", subsystems: .offlineSupport)
            self?.getExistingChannelIds { channels in
                preSyncChannelIds = channels
                done(.continue)
            }
        })

        // 1. Call `/sync` endpoint and get missing events for all locally existed channels
        var synchedChannelIds: Set<ChannelId> = Set(preSyncChannelIds)
        let syncEvents = AsyncOperation(maxRetries: maxRetriesCount) { [weak self] done in
            log.info(
                "1. Call `/sync` endpoint and get missing events for all locally existed channels",
                subsystems: .offlineSupport
            )
            self?.getUser { user in
                guard let lastPendingConnectionDate = user?.lastPendingConnectionDate else {
                    done(.continue)
                    return
                }

                self?.syncMissingEvents(
                    using: lastPendingConnectionDate,
                    channelIds: preSyncChannelIds,
                    bumpLastSync: false
                ) { result in
                    switch result {
                    case let .success(channelIds):
                        synchedChannelIds = Set(channelIds)
                        // As per our sync logic, we should keep the last connection date.
                        self?.updateUserValue(
                            { $0?.lastPendingConnectionDate = self?.lastConnection },
                            completion: { _ in done(.continue) }
                        )
                    case let .failure(error):
                        synchedChannelIds = Set([])
                        done(error.shouldRetry ? .retry : .continue)
                    }
                }
            }
        }
        operations.append(syncEvents)

        // 2. Start watching open channels.
        // We keep track of the watched channels to avoid clearing them out in future steps
        var watchedChannelIds: Set<ChannelId> = []
        let refetchChannelOperations: [AsyncOperation] = activeChannelControllers.allObjects.compactMap { controller in
            // Reset only the controllers that need recovery
            guard controller.isAvailableOnRemote else { return nil }
            if let cid = controller.cid, synchedChannelIds.contains(cid) {
                return nil
            }
            return AsyncOperation(maxRetries: maxRetriesCount) { [weak self] done in
                log.info("2. Start watching open channel", subsystems: .offlineSupport)
                self?.watchActiveChannel(for: controller) { result in
                    switch result {
                    case let .success(channelId):
                        watchedChannelIds.insert(channelId)
                        done(.continue)
                    case let .failure(error):
                        done(error.shouldRetry ? .retry : .continue)
                    }
                }
            }
        }
        operations.append(contentsOf: refetchChannelOperations)

        // 3. Refetch channel lists queries, link only what backend returns (the 1st page)
        // 4. Clean up local message history for channels that are outdated/will get outdated
        // We use `synchedChannelIds` to keep track of the channels that were synched both in the previous step and
        // after each ChannelListController recovery.
        let refetchChannelListQueryOperations: [AsyncOperation] = activeChannelListControllers.allObjects.compactMap { controller in
            // Reset only the controllers that need recovery
            guard controller.isAvailableOnRemote else { return nil }

            return AsyncOperation(maxRetries: maxRetriesCount) { [weak self] done in
                log.info("3. Refetch channel lists queries & 4. Clean up local message history", subsystems: .offlineSupport)
                self?.resetChannelsQuery(
                    for: controller,
                    watchedChannelIds: watchedChannelIds,
                    synchedChannelIds: synchedChannelIds
                ) { result in
                    switch result {
                    case let .success(channels):
                        let queryChannelIds = channels.map(\.cid)
                        synchedChannelIds = synchedChannelIds.union(queryChannelIds)
                        done(.continue)
                    case let .failure(error):
                        done(error.shouldRetry ? .retry : .continue)
                    }
                }
            }
        }
        operations.append(contentsOf: refetchChannelListQueryOperations)

        // 5. Bump the last sync timestamp
        operations.append(AsyncOperation { [weak self] done in
            log.info("5. Bump the last sync timestamp", subsystems: .offlineSupport)
            self?.updateUserValue { user in
                user?.lastSyncAt = Date()
            } completion: { _ in
                done(.continue)
            }
        })

        operations.append(BlockOperation(block: {
            log.info("Finished recovering offline state", subsystems: .offlineSupport)
            DispatchQueue.main.async {
                completion()
            }
        }))

        // We are making sure the operations happen sequentially one after the other by setting one as the dependency
        // of the following one
        var previousOperation: Operation?
        operations.reversed().forEach { operation in
            defer { previousOperation = operation }
            guard let previousOperation = previousOperation else { return }
            previousOperation.addDependency(operation)
        }

        operationQueue.addOperations(operations, waitUntilFinished: false)
    }

    /// Receives a date when the connection has been stablished
    /// It updates user's lastPendingConnectionDate if there's no other pending date. If there is another pending date, this date passed as parameter is stored in
    /// memory for this class to use it when needed
    /// - Parameter date: Date of the connection
    func updateLastPendingConnectionDate(with date: Date) {
        // We store the last connection date in memory.
        lastConnection = date
        updateUserValue { user in
            // If there's a pending connection date, it means there was an issue retrieving all the past events.
            // If that's the case, we keep the existing one.
            guard let user = user, user.lastPendingConnectionDate == nil else { return }
            log.info("Updating last pending connection date", subsystems: .offlineSupport)
            user.lastPendingConnectionDate = date
        }
    }

    /// Syncs the events for the active chat channels using the last sync date.
    /// - Parameter completion: A block that will get executed upon completion of the synchronization
    func syncExistingChannelsEvents(completion: @escaping (Result<[ChannelId], SyncError>) -> Void) {
        getUser { [weak self, syncCooldown] user in
            guard let lastSyncAt = user?.lastSyncAt else {
                // That's the first session of the current user. Bump `lastSyncAt` with current time and return.
                self?.updateUserValue({
                    $0?.lastSyncAt = Date()
                }, completion: { _ in
                    completion(.failure(.noNeedToSync))
                })
                return
            }

            guard Date().timeIntervalSince(lastSyncAt) > syncCooldown else {
                completion(.failure(.noNeedToSync))
                return
            }

            self?.getExistingChannelIds { channelIds in
                self?.syncMissingEvents(
                    using: lastSyncAt,
                    channelIds: channelIds,
                    bumpLastSync: true,
                    completion: completion
                )
            }
        }
    }

    private func syncMissingEvents(
        using date: Date,
        channelIds: [ChannelId],
        bumpLastSync: Bool,
        completion: @escaping (Result<[ChannelId], SyncError>) -> Void
    ) {
        guard config.isLocalStorageEnabled else {
            completion(.failure(.localStorageDisabled))
            return
        }

        guard !channelIds.isEmpty else {
            completion(.success([]))
            return
        }

        log.info("Synching events for existing channels since \(date)", subsystems: .offlineSupport)
        getMissingEvents(since: date, channelIds: channelIds) { [weak self] result in
            switch result {
            case let .success(payload):
                guard bumpLastSync else {
                    log.info("Successfully synched events", subsystems: .offlineSupport)
                    completion(.success(channelIds))
                    return
                }

                log.info("Bumping last sync date", subsystems: .offlineSupport)
                self?.updateUserValue({
                    $0?.lastSyncAt = payload.eventPayloads.first?.createdAt ?? date
                }) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(channelIds))
                    }
                }
            case let .failure(error):
                guard case .tooManyEvents = error else {
                    completion(.failure(error))
                    return
                }
                // Backend responds with 400 if there was more than 1000 events to replay
                // Cleaning local channels data and refetching it from scratch
                log.info("/sync returned too many events. Continuing...", subsystems: .offlineSupport)
                completion(.success([]))
            }
        }
    }

    private func getMissingEvents(
        since lastSyncDate: Date,
        channelIds: [ChannelId],
        completion: @escaping (Result<MissingEventsPayload, SyncError>) -> Void
    ) {
        let endpoint: Endpoint<MissingEventsPayload> = .missingEvents(since: lastSyncDate, cids: channelIds)

        apiClient.request(endpoint: endpoint) { [weak self] result in
            switch result {
            case let .success(payload):
                log.info("Processing pending events. Count \(payload.eventPayloads.count)", subsystems: .offlineSupport)
                self?.eventNotificationCenter.process(
                    payload.eventPayloads.asEvents(),
                    postNotifications: false
                ) {
                    log.info(
                        "Successfully processed pending events. Count \(payload.eventPayloads.count)",
                        subsystems: .offlineSupport
                    )
                    completion(.success(payload))
                }
            case let .failure(error):
                log.error("Failed synching events: \(error).", subsystems: .offlineSupport)
                guard error.isBackendErrorWith400StatusCode else {
                    completion(.failure(.syncEndpointFailed(error)))
                    return
                }
                completion(.failure(.tooManyEvents(error)))
            }
        }
    }

    private func watchActiveChannel(
        for controller: ChatChannelController,
        completion: @escaping (Result<ChannelId, SyncError>) -> Void
    ) {
        let cidString = (controller.cid?.rawValue ?? "unknown")
        log.info("Watching active channel \(cidString)", subsystems: .offlineSupport)
        controller.watchActiveChannel { error in
            if let error = error {
                log.error("Failed watching active channel \(cidString): \(error)", subsystems: .offlineSupport)
                completion(.failure(.watchingActiveChannelFailed(error)))
            } else if let cid = controller.cid {
                log.info("Successfully watched active channel \(cidString)", subsystems: .offlineSupport)
                completion(.success(cid))
            } else {
                log.error("Failed watching active channel \(cidString): Missing channel id", subsystems: .offlineSupport)
                completion(.failure(.missingChannelId))
            }
        }
    }

    private func resetChannelsQuery(
        for controller: ChatChannelListController,
        watchedChannelIds: Set<ChannelId>,
        synchedChannelIds: Set<ChannelId>,
        completion: @escaping (Result<[ChatChannel], SyncError>) -> Void
    ) {
        log.info("Refetching query for \(controller.query.debugDescription)", subsystems: .offlineSupport)

        channelRepository.resetChannelsQuery(
            for: controller.query,
            watchedChannelIds: watchedChannelIds,
            synchedChannelIds: synchedChannelIds
        ) { result in
            switch result {
            case let .success(channels):
                log.info("Successfully refetched query for \(controller.query.debugDescription)", subsystems: .offlineSupport)
                completion(.success(channels))
            case let .failure(error):
                log.error("Failed refetching query for \(controller.query.debugDescription): \(error)", subsystems: .offlineSupport)
                completion(.failure(.resettingQueryFailed(error)))
            }
        }
    }

    private func getExistingChannelIds(completion: @escaping ([ChannelId]) -> Void) {
        database.write { session in
            let cids =
                session
                    .loadAllChannelListQueries()
                    .flatMap(\.channels)
                    .compactMap { try? ChannelId(cid: $0.cid) }
            log.info("Retrieved channels from existing queries from DB. Count \(cids.count)", subsystems: .offlineSupport)
            completion(cids)
        }
    }

    private func getUser(_ completion: @escaping (CurrentUserDTO?) -> Void) {
        let context = database.viewContext
        context.perform {
            log.info("Retrieved CurrentUserDTO from DB", subsystems: .offlineSupport)
            completion(context.currentUser)
        }
    }

    private func updateUserValue(
        _ block: @escaping (inout CurrentUserDTO?) -> Void,
        completion: ((SyncError?) -> Void)? = nil
    ) {
        database.write { session in
            var currentUser = session.currentUser
            block(&currentUser)
        } completion: { error in
            if let error = error {
                log.error("Failed updating value: \(error)", subsystems: .offlineSupport)
                completion?(.couldNotUpdateUserValue(error))
            } else {
                log.info("Updated user value", subsystems: .offlineSupport)
                completion?(nil)
            }
        }
    }
}
