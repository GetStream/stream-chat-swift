//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

enum SyncError: Error, Sendable {
    case noNeedToSync
    case tooManyEvents(Error)
    case syncEndpointFailed(Error)
    case couldNotUpdateUserValue(Error)
    case failedFetchingChannels

    var shouldRetry: Bool {
        switch self {
        case .noNeedToSync, .tooManyEvents, .couldNotUpdateUserValue:
            return false
        case .syncEndpointFailed, .failedFetchingChannels:
            return true
        }
    }
}

/// Controls when `/sync` event payloads are replayed versus skipped in favor of a `queryChannels` refresh.
struct SyncEventReplayPolicy: Sendable {
    /// Maximum number of events that may be replayed from a single `/sync` response.
    var maximumEventCount: Int

    /// Conservative default below the backend hard cap (~2000).
    static let `default` = SyncEventReplayPolicy(maximumEventCount: 250)
}

/// This class is in charge of the synchronization of our local storage with the remote.
/// When executing a sync, it will remove outdated elements, and will refresh the content to always show the latest data.
class SyncRepository: @unchecked Sendable {
    enum Constants {
        static let maximumDaysSinceLastSync = 30
        static let maximumChannelIdsPerRequest = 100
    }

    /// Maximum number of retries for each operation step.
    private let maxRetriesCount = 2
    private let config: ChatClientConfig
    private let database: DatabaseContainer
    private let apiClient: APIClient
    private let channelListUpdater: ChannelListUpdater
    let eventReplayPolicy: SyncEventReplayPolicy
    let offlineRequestsRepository: OfflineRequestsRepository
    let eventNotificationCenter: EventNotificationCenter

    let activeChannelControllers = ThreadSafeWeakCollection<ChatChannelController>()
    let activeChannelListControllers = ThreadSafeWeakCollection<ChatChannelListController>()
    let activeChats = ThreadSafeWeakCollection<Chat>()
    let activeLivestreamChats = ThreadSafeWeakCollection<LivestreamChat>()
    let activeLivestreamControllers = ThreadSafeWeakCollection<LivestreamChannelController>()
    let activeChannelLists = ThreadSafeWeakCollection<ChannelList>()

    private lazy var operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.name = "com.stream.sync-repository"
        operationQueue.qualityOfService = .utility
        return operationQueue
    }()

    init(
        config: ChatClientConfig,
        offlineRequestsRepository: OfflineRequestsRepository,
        eventNotificationCenter: EventNotificationCenter,
        database: DatabaseContainer,
        apiClient: APIClient,
        channelListUpdater: ChannelListUpdater,
        eventReplayPolicy: SyncEventReplayPolicy = .default
    ) {
        self.config = config
        self.offlineRequestsRepository = offlineRequestsRepository
        self.channelListUpdater = channelListUpdater
        self.eventNotificationCenter = eventNotificationCenter
        self.database = database
        self.apiClient = apiClient
        self.eventReplayPolicy = eventReplayPolicy
    }

    deinit {
        cancelRecoveryFlow()
    }

    // MARK: - Tracking Active

    func startTrackingChat(_ chat: Chat) {
        guard !activeChats.contains(chat) else { return }
        activeChats.add(chat)
    }

    func stopTrackingChat(_ chat: Chat) {
        activeChats.remove(chat)
    }

    func startTrackingChannelController(_ controller: ChatChannelController) {
        guard !activeChannelControllers.contains(controller) else { return }
        activeChannelControllers.add(controller)
    }

    func stopTrackingChannelController(_ controller: ChatChannelController) {
        activeChannelControllers.remove(controller)
    }

    func startTrackingLivestreamController(_ controller: LivestreamChannelController) {
        guard !activeLivestreamControllers.contains(controller) else { return }
        activeLivestreamControllers.add(controller)
    }

    func stopTrackingLivestreamController(_ controller: LivestreamChannelController) {
        activeLivestreamControllers.remove(controller)
    }

    func startTrackingLivestreamChat(_ livestreamChat: LivestreamChat) {
        guard !activeLivestreamChats.contains(livestreamChat) else { return }
        activeLivestreamChats.add(livestreamChat)
    }

    func stopTrackingLivestreamChat(_ livestreamChat: LivestreamChat) {
        activeLivestreamChats.remove(livestreamChat)
    }

    func startTrackingChannelList(_ channelList: ChannelList) {
        guard !activeChannelLists.contains(channelList) else { return }
        activeChannelLists.add(channelList)
    }

    func stopTrackingChannelList(_ channelList: ChannelList) {
        activeChannelLists.remove(channelList)
    }

    func startTrackingChannelListController(_ controller: ChatChannelListController) {
        guard !activeChannelListControllers.contains(controller) else { return }
        activeChannelListControllers.add(controller)
    }

    func stopTrackingChannelListController(_ controller: ChatChannelListController) {
        activeChannelListControllers.remove(controller)
    }

    func removeAllTracked() {
        activeChats.removeAllObjects()
        activeLivestreamChats.removeAllObjects()
        activeChannelControllers.removeAllObjects()
        activeChannelLists.removeAllObjects()
        activeChannelListControllers.removeAllObjects()
        activeLivestreamControllers.removeAllObjects()
    }

    // MARK: - Syncing
    
    func syncLocalState(completion: @escaping @Sendable () -> Void) {
        cancelRecoveryFlow()

        getUser { [weak self] in
            guard let currentUser = $0 else {
                log.error("Current user must exist", subsystems: .offlineSupport)
                completion()
                return
            }

            guard let lastSyncAt = currentUser.lastSynchedEventDate?.bridgeDate else {
                log.info("It's the first session of the current user, skipping recovery flow", subsystems: .offlineSupport)
                self?.updateLastSyncAt(with: Date(), completion: { _ in
                    completion()
                })
                return
            }
            self?.syncLocalState(lastSyncAt: lastSyncAt, completion: completion)
        }
    }

    // MARK: -

    /// Runs offline tasks and updates the local state for channels
    ///
    /// Recovery mode (pauses regular API requests while it is running)
    /// 1. Enter recovery
    /// 2. Runs offline API requests
    /// 3. Exit recovery
    ///
    /// Background mode (other regular API requests are allowed to run at the same time)
    /// 1. Collect all the **active** channel ids (from instances of `Chat`, `ChannelList`, `ChatChannelController`, `ChatChannelListController`)
    /// 2. Refresh channel lists (channels for current pages in `ChannelList`, `ChatChannelListController`, including grouped lists)
    /// 3. Apply updates from the /sync endpoint for channels not in active channel lists
    ///      * channel controllers targeting other channels
    ///      * no channel lists active, but channel controllers are
    ///      * oversized payloads skip event replay and refresh active watched channels via queryChannels
    /// 4. Re-watch channels what we were watching before disconnect
    private func syncLocalState(lastSyncAt: Date, completion: @escaping @Sendable () -> Void) {
        let context = SyncContext(lastSyncAt: lastSyncAt)
        var operations: [Operation] = []
        let start = CFAbsoluteTimeGetCurrent()

        //
        // Recovery mode operations (other API requests are paused)
        //
        if config.isLocalStorageEnabled {
            apiClient.enterRecoveryMode()
            operations.append(ExecutePendingOfflineActions(offlineRequestsRepository: offlineRequestsRepository))
            operations.append(BlockOperation(block: { [apiClient] in
                apiClient.exitRecoveryMode()
            }))
        }

        //
        // Background mode operations
        //
        if config.isAutomaticSyncOnReconnectEnabled {
            log.info("Starting to refresh offline state", subsystems: .offlineSupport)
            
            /// 1. Collect all the **active** channel ids
            operations.append(ActiveChannelIdsOperation(syncRepository: self, context: context))
            
            // 2. Refresh channel lists (non-grouped lists individually, grouped lists via a single shared request)
            let allChannelLists = activeChannelLists.allObjects
            operations.append(contentsOf: allChannelLists
                .filter { $0.groupKey == nil }
                .map { RefreshChannelListOperation(channelList: $0, context: context) }
            )
            operations.append(contentsOf: activeChannelListControllers.allObjects
                .map { RefreshChannelListOperation(controller: $0, context: context) }
            )
            let groupedChannelLists = allChannelLists.filter { $0.groupKey != nil }
            if !groupedChannelLists.isEmpty {
                operations.append(SyncGroupedChannelsOperation(
                    channelListUpdater: channelListUpdater,
                    groupedChannelLists: groupedChannelLists,
                    context: context
                ))
            }

            // 3. /sync (for channels what not part of active channel lists)
            operations.append(SyncEventsOperation(syncRepository: self, context: context, recovery: false))
            
            // 4. Re-watch channels what we were watching before disconnect
            // Needs to be done explicitly after reconnection, otherwise SDK users need to handle connection changes
            operations.append(contentsOf: activeChannelControllers.allObjects.map {
                WatchChannelOperation(controller: $0, context: context, recovery: false)
            })
            operations.append(contentsOf: activeChats.allObjects.map {
                WatchChannelOperation(chat: $0, context: context)
            })
            operations.append(contentsOf: activeLivestreamChats.allObjects.map {
                WatchChannelOperation(livestreamChat: $0, context: context)
            })
            operations.append(contentsOf: activeLivestreamControllers.allObjects.map {
                WatchChannelOperation(livestreamController: $0, context: context, recovery: false)
            })
            
            operations.append(BlockOperation(block: {
                let duration = CFAbsoluteTimeGetCurrent() - start
                log.info("Finished refreshing offline state (\(context.synchedChannelIds.count) channels in \(String(format: "%.1f", duration)) seconds)", subsystems: .offlineSupport)
                DispatchQueue.main.async {
                    completion()
                }
            }))
        } else {
            // When automatic sync is disabled, still call completion after recovery operations finish
            operations.append(BlockOperation(block: {
                DispatchQueue.main.async {
                    completion()
                }
            }))
        }

        var previousOperation: Operation?
        operations.reversed().forEach { operation in
            defer { previousOperation = operation }
            guard let previousOperation = previousOperation else { return }
            previousOperation.addDependency(operation)
        }
        operationQueue.addOperations(operations, waitUntilFinished: false)
    }

    func cancelRecoveryFlow() {
        operationQueue.cancelAllOperations()
        apiClient.exitRecoveryMode()
    }

    func syncChannelsEvents(
        channelIds: [ChannelId],
        lastSyncAt: Date,
        isRecovery: Bool,
        alreadySyncedChannelIds: Set<ChannelId> = [],
        completion: @escaping @Sendable (Result<[ChannelId], SyncError>) -> Void
    ) {
        guard lastSyncAt.numberOfDaysUntilNow < Constants.maximumDaysSinceLastSync else {
            log.info(
                "Skipping `/sync` because lastSyncAt (\(lastSyncAt)) is older than \(Constants.maximumDaysSinceLastSync) days",
                subsystems: .offlineSupport
            )
            updateLastSyncAt(with: Date()) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success([]))
                }
            }
            return
        }

        syncMissingEvents(
            using: lastSyncAt,
            channelIds: channelIds,
            isRecoveryRequest: isRecovery,
            alreadySyncedChannelIds: alreadySyncedChannelIds,
            completion: completion
        )
    }

    /// Refreshes actively watched channels via `queryChannels`, excluding channels already synced in the reconnect context.
    func refreshActiveWatchedChannels(
        excluding alreadySyncedChannelIds: Set<ChannelId>,
        completion: @escaping @Sendable (Result<Set<ChannelId>, SyncError>) -> Void
    ) {
        var channelIds = Set<ChannelId>()
        channelIds.formUnion(activeChannelControllers.allObjects.compactMap(\.cid))
        channelIds.formUnion(activeLivestreamControllers.allObjects.compactMap(\.cid))
        channelIds.formUnion(activeLivestreamChats.allObjects.compactMap { try? $0.cid })
        let chats = activeChats.allObjects

        let finish: @Sendable (Set<ChannelId>) -> Void = { [weak self] ids in
            guard let self else {
                completion(.success([]))
                return
            }
            let idsToRefresh = Array(ids.subtracting(alreadySyncedChannelIds))
            guard !idsToRefresh.isEmpty else {
                completion(.success([]))
                return
            }
            self.startWatchingChannelsInBatches(idsToRefresh, accumulated: [], completion: completion)
        }

        if chats.isEmpty {
            finish(channelIds)
        } else {
            DispatchQueue.main.async {
                var ids = channelIds
                ids.formUnion(chats.compactMap { try? $0.cid })
                finish(ids)
            }
        }
    }

    private func getUser(completion: @escaping @Sendable (CurrentUserDTO?) -> Void) {
        nonisolated(unsafe) var user: CurrentUserDTO?
        database.backgroundReadOnlyContext.perform {
            user = self.database.backgroundReadOnlyContext.currentUser
            completion(user)
        }
    }

    private func syncMissingEvents(
        using date: Date,
        channelIds: [ChannelId],
        isRecoveryRequest: Bool,
        alreadySyncedChannelIds: Set<ChannelId>,
        completion: @escaping @Sendable (Result<[ChannelId], SyncError>) -> Void
    ) {
        log.info(
            "Synching events for \(channelIds.count) channel(s) since \(date). replayThreshold=\(eventReplayPolicy.maximumEventCount) alreadySyncedExcluded=\(alreadySyncedChannelIds.count)",
            subsystems: .offlineSupport
        )

        guard !channelIds.isEmpty else {
            completion(.success([]))
            return
        }

        let endpoint: Endpoint<MissingEventsPayload> = .missingEvents(since: date, cids: channelIds)
        let requestCompletion: @Sendable (Result<MissingEventsPayload, Error>) -> Void = { [weak self] result in
            switch result {
            case let .success(payload):
                guard let self else { return }
                let eventCount = payload.eventPayloads.count
                let maximumEventCount = self.eventReplayPolicy.maximumEventCount
                log.info(
                    "Received `/sync` payload with \(eventCount) event(s). replayThreshold=\(maximumEventCount)",
                    subsystems: .offlineSupport
                )
                if eventCount > maximumEventCount {
                    log.info(
                        "Skipping event replay; count \(eventCount) exceeds \(maximumEventCount). Refreshing watched channels instead.",
                        subsystems: .offlineSupport
                    )
                    self.handleSyncEventReplayFallback(
                        lastSyncAt: payload.eventPayloads.last?.createdAt ?? date,
                        alreadySyncedChannelIds: alreadySyncedChannelIds,
                        completion: completion
                    )
                    return
                }

                log.info("Processing pending events. Count \(eventCount)", subsystems: .offlineSupport)
                self.processMissingEventsPayload(payload) { [weak self] in
                    self?.updateLastSyncAt(with: payload.eventPayloads.last?.createdAt ?? date, completion: { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(channelIds))
                        }
                    })
                }
            case let .failure(error):
                log.error("Failed synching events: \(error).", subsystems: .offlineSupport)
                guard error.isBackendErrorWith400StatusCode else {
                    completion(.failure(.syncEndpointFailed(error)))
                    return
                }
                // Backend responds with 400 if there were more than 2000 events to return
                log.info("/sync returned too many events. Refreshing watched channels instead.", subsystems: .offlineSupport)
                self?.handleSyncEventReplayFallback(
                    lastSyncAt: Date(),
                    alreadySyncedChannelIds: alreadySyncedChannelIds,
                    completion: completion
                )
            }
        }

        if isRecoveryRequest {
            apiClient.recoveryRequest(endpoint: endpoint, completion: requestCompletion)
        } else {
            apiClient.request(endpoint: endpoint, completion: requestCompletion)
        }
    }

    private func handleSyncEventReplayFallback(
        lastSyncAt: Date,
        alreadySyncedChannelIds: Set<ChannelId>,
        completion: @escaping @Sendable (Result<[ChannelId], SyncError>) -> Void
    ) {
        log.info(
            "Running `/sync` fallback via queryChannels. excludingAlreadySynced=\(alreadySyncedChannelIds.count)",
            subsystems: .offlineSupport
        )
        refreshActiveWatchedChannels(excluding: alreadySyncedChannelIds) { [weak self] result in
            switch result {
            case let .success(refreshedIds):
                log.info(
                    "Fallback refreshed \(refreshedIds.count) watched channel(s). Updating lastSyncAt to \(lastSyncAt)",
                    subsystems: .offlineSupport
                )
                guard let self else {
                    completion(.failure(.couldNotUpdateUserValue(ClientError("SyncRepository deallocated"))))
                    return
                }
                self.updateLastSyncAt(with: lastSyncAt) { error in
                    if let error {
                        completion(.failure(error))
                    } else {
                        completion(.success(Array(refreshedIds)))
                    }
                }
            case let .failure(error):
                log.error("Fallback queryChannels failed: \(error)", subsystems: .offlineSupport)
                completion(.failure(error))
            }
        }
    }

    private func startWatchingChannelsInBatches(
        _ channelIds: [ChannelId],
        accumulated: Set<ChannelId>,
        completion: @escaping @Sendable (Result<Set<ChannelId>, SyncError>) -> Void
    ) {
        guard !channelIds.isEmpty else {
            completion(.success(accumulated))
            return
        }

        let batch = Array(channelIds.prefix(Constants.maximumChannelIdsPerRequest))
        let remaining = Array(channelIds.dropFirst(Constants.maximumChannelIdsPerRequest))
        channelListUpdater.startWatchingChannels(withIds: batch) { [weak self] error in
            if error != nil {
                completion(.failure(.failedFetchingChannels))
                return
            }
            var nextAccumulated = accumulated
            nextAccumulated.formUnion(batch)
            guard let self else {
                completion(.failure(.failedFetchingChannels))
                return
            }
            self.startWatchingChannelsInBatches(remaining, accumulated: nextAccumulated, completion: completion)
        }
    }

    private func updateLastSyncAt(with date: Date, completion: @escaping @Sendable (SyncError?) -> Void) {
        database.write { session in
            session.currentUser?.lastSynchedEventDate = date.bridgeDate
        } completion: { error in
            if let error = error {
                log.error("Failed updating value: \(error)", subsystems: .offlineSupport)
                completion(.couldNotUpdateUserValue(error))
            } else {
                log.info("Updated user value", subsystems: .offlineSupport)
                completion(nil)
            }
        }
    }

    private func processMissingEventsPayload(_ payload: MissingEventsPayload, completion: @escaping @Sendable () -> Void) {
        eventNotificationCenter.process(payload.eventPayloads.asEvents(), postNotifications: false) {
            log.info(
                "Successfully processed pending events. Count \(payload.eventPayloads.count)",
                subsystems: .offlineSupport
            )
            completion()
        }
    }

    func queueOfflineRequest(endpoint: DataEndpoint) {
        guard config.isLocalStorageEnabled else { return }
        offlineRequestsRepository.queueOfflineRequest(endpoint: endpoint)
    }
}

private extension Date {
    var numberOfDaysUntilNow: Int {
        Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
    }
}
