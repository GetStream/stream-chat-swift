//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum SyncError: Error {
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

/// This class is in charge of the synchronization of our local storage with the remote.
/// When executing a sync, it will remove outdated elements, and will refresh the content to always show the latest data.
class SyncRepository {
    private enum Constants {
        static let maximumDaysSinceLastSync = 30
    }

    /// Maximum number of retries for each operation step.
    private let maxRetriesCount = 2
    private let config: ChatClientConfig
    private let database: DatabaseContainer
    private let apiClient: APIClient
    private let channelListUpdater: ChannelListUpdater
    let offlineRequestsRepository: OfflineRequestsRepository
    let eventNotificationCenter: EventNotificationCenter

    let activeChannelControllers = ThreadSafeWeakCollection<ChatChannelController>()
    let activeChannelListControllers = ThreadSafeWeakCollection<ChatChannelListController>()
    let activeChats = ThreadSafeWeakCollection<Chat>()
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
        channelListUpdater: ChannelListUpdater
    ) {
        self.config = config
        self.offlineRequestsRepository = offlineRequestsRepository
        self.channelListUpdater = channelListUpdater
        self.eventNotificationCenter = eventNotificationCenter
        self.database = database
        self.apiClient = apiClient
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
        activeChannelControllers.removeAllObjects()
        activeChannelLists.removeAllObjects()
        activeChannelListControllers.removeAllObjects()
        activeLivestreamControllers.removeAllObjects()
    }

    // MARK: - Syncing

    func syncLocalState(completion: @escaping () -> Void) {
        cancelRecoveryFlow()

        getUser { [weak self] in
            guard let currentUser = $0 else {
                log.error("Current user must exist", subsystems: .offlineSupport)
                completion()
                return
            }

            guard let lastSyncAt = currentUser.lastSynchedEventDate?.bridgeDate else {
                log.info("It's the first session of the current user, skipping recovery flow", subsystems: .offlineSupport)
                self?.updateUserValue({ $0?.lastSynchedEventDate = DBDate() }) { _ in
                    completion()
                }
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
    /// 2. Refresh channel lists (channels for current pages in `ChannelList`, `ChatChannelListController`)
    /// 3. Apply updates from the /sync endpoint for channels not in active channel lists (max 2000 events is supported)
    ///      * channel controllers targeting other channels
    ///      * no channel lists active, but channel controllers are
    /// 4. Re-watch channels what we were watching before disconnect
    private func syncLocalState(lastSyncAt: Date, completion: @escaping () -> Void) {
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
            
            // 2. Refresh channel lists
            operations.append(contentsOf: activeChannelLists.allObjects.map { RefreshChannelListOperation(channelList: $0, context: context) })
            operations.append(contentsOf: activeChannelListControllers.allObjects.map { RefreshChannelListOperation(controller: $0, context: context) })
            
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
        completion: @escaping (Result<[ChannelId], SyncError>) -> Void
    ) {
        guard lastSyncAt.numberOfDaysUntilNow < Constants.maximumDaysSinceLastSync else {
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
            completion: completion
        )
    }

    private func getUser(completion: @escaping (CurrentUserDTO?) -> Void) {
        var user: CurrentUserDTO?
        database.backgroundReadOnlyContext.perform {
            user = self.database.backgroundReadOnlyContext.currentUser
            completion(user)
        }
    }

    private func syncMissingEvents(
        using date: Date,
        channelIds: [ChannelId],
        isRecoveryRequest: Bool,
        completion: @escaping (Result<[ChannelId], SyncError>) -> Void
    ) {
        log.info("Synching events for existing channels since \(date)", subsystems: .offlineSupport)

        guard !channelIds.isEmpty else {
            completion(.success([]))
            return
        }

        let endpoint: Endpoint<MissingEventsPayload> = .missingEvents(since: date, cids: channelIds)
        let requestCompletion: (Result<MissingEventsPayload, Error>) -> Void = { [weak self] result in
            switch result {
            case let .success(payload):
                log.info("Processing pending events. Count \(payload.eventPayloads.count)", subsystems: .offlineSupport)
                self?.processMissingEventsPayload(payload) {
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
                // Cleaning local channels data and refetching it from scratch
                log.info("/sync returned too many events. Continuing...", subsystems: .offlineSupport)

                self?.updateLastSyncAt(with: Date()) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success([]))
                    }
                }
            }
        }

        if isRecoveryRequest {
            apiClient.recoveryRequest(endpoint: endpoint, completion: requestCompletion)
        } else {
            apiClient.request(endpoint: endpoint, completion: requestCompletion)
        }
    }

    private func updateLastSyncAt(with date: Date, completion: @escaping (SyncError?) -> Void) {
        updateUserValue({
            $0?.lastSynchedEventDate = date.bridgeDate
        }, completion: completion)
    }

    private func processMissingEventsPayload(_ payload: MissingEventsPayload, completion: @escaping () -> Void) {
        eventNotificationCenter.process(payload.eventPayloads.asEvents(), postNotifications: false) {
            log.info(
                "Successfully processed pending events. Count \(payload.eventPayloads.count)",
                subsystems: .offlineSupport
            )
            completion()
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
