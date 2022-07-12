//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
    /// Do not call the sync endpoint more than once every six seconds
    private let syncCooldown: TimeInterval = 6.0
    /// Maximum number of retries for each operation step.
    private let maxRetriesCount = 2
    private let config: ChatClientConfig
    private let database: DatabaseContainer
    private let apiClient: APIClient
    let activeChannelControllers: ThreadSafeWeakCollection<ChatChannelController>
    let activeChannelListControllers: ThreadSafeWeakCollection<ChatChannelListController>
    let offlineRequestsRepository: OfflineRequestsRepository
    let eventNotificationCenter: EventNotificationCenter

    private lazy var operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.name = "com.stream.sync-repository"
        return operationQueue
    }()

    init(
        config: ChatClientConfig,
        activeChannelControllers: ThreadSafeWeakCollection<ChatChannelController>,
        activeChannelListControllers: ThreadSafeWeakCollection<ChatChannelListController>,
        offlineRequestsRepository: OfflineRequestsRepository,
        eventNotificationCenter: EventNotificationCenter,
        database: DatabaseContainer,
        apiClient: APIClient
    ) {
        self.config = config
        self.activeChannelControllers = activeChannelControllers
        self.activeChannelListControllers = activeChannelListControllers
        self.offlineRequestsRepository = offlineRequestsRepository
        self.eventNotificationCenter = eventNotificationCenter
        self.database = database
        self.apiClient = apiClient
    }
    
    deinit {
        cancelRecoveryFlow()
    }
    
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

    /// Syncs the local state with the server to make sure the local database is up to date.
    /// It features queuing, serialization and retries
    ///
    /// [Sync and watch channels](https://www.notion.so/2-Sync-and-watch-channels-ac44feb55de3482f8f0f99e100ca40c6)
    /// 1. Call `/sync` endpoint and get missing events for all locally existed channels
    /// 2. Start watching open channels
    /// 3. Refetch channel lists queries, link only what backend returns (the 1st page)
    /// 4. Clean up unwanted channels
    /// 5. Run offline actions requests
    ///
    /// - Parameter completion: A block that will get executed upon completion of the synchronization
    private func syncLocalState(lastSyncAt: Date, completion: @escaping () -> Void) {
        log.info("Starting to recover offline state", subsystems: .offlineSupport)
        let context = SyncContext(lastSyncAt: lastSyncAt)
        var operations: [Operation] = []

        // Enter recovery mode so no other requests are triggered.
        apiClient.enterRecoveryMode()

        // Get the existing channelIds
        operations.append(GetChannelIdsOperation(database: database, context: context))
        
        if context.localChannelIds.isEmpty {
            context.localChannelIds = activeChannelControllers.allObjects.compactMap { $0.cid }
        }

        // 1. Call `/sync` endpoint and get missing events for all locally existed channels
        operations.append(SyncEventsOperation(syncRepository: self, context: context))

        // 2. Start watching open channels.
        let watchChannelOperations: [AsyncOperation] = activeChannelControllers.allObjects.map { controller in
            WatchChannelOperation(controller: controller, context: context)
        }
        operations.append(contentsOf: watchChannelOperations)

        // 3. Refetch channel lists queries, link only what backend returns (the 1st page)
        // We use `context.synchedChannelIds` to keep track of the channels that were synched both in the previous step and
        // after each ChannelListController recovery.
        let refetchChannelListQueryOperations: [AsyncOperation] = activeChannelListControllers.allObjects
            .map { controller in
                RefetchChannelListQueryOperation(
                    controller: controller,
                    context: context
                )
            }
        operations.append(contentsOf: refetchChannelListQueryOperations)

        // 4. Clean up unwanted channels
        operations.append(DeleteUnwantedChannelsOperation(database: database, context: context))

        // 5. Run offline actions requests
        if config.isLocalStorageEnabled {
            operations.append(ExecutePendingOfflineActions(offlineRequestsRepository: offlineRequestsRepository))
        }

        operations.append(BlockOperation(block: { [weak self] in
            log.info("Finished recovering offline state", subsystems: .offlineSupport)
            DispatchQueue.main.async {
                self?.apiClient.exitRecoveryMode()
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

    /// Syncs the events for the active chat channels using the last sync date.
    /// - Parameter completion: A block that will get executed upon completion of the synchronization
    func syncExistingChannelsEvents(completion: @escaping (Result<[ChannelId], SyncError>) -> Void) {
        getUser { [weak self] currentUser in
            guard let lastSyncAt = currentUser?.lastSynchedEventDate?.bridgeDate else {
                completion(.failure(.noNeedToSync))
                return
            }
            
            self?.getChannelIds { channelIds in
                self?.syncChannelsEvents(
                    channelIds: channelIds,
                    lastSyncAt: lastSyncAt,
                    isRecovery: false,
                    completion: completion
                )
            }
        }
    }
    
    func cancelRecoveryFlow() {
        operationQueue.cancelAllOperations()
        apiClient.exitRecoveryMode()
    }

    private func getChannelIds(completion: @escaping ([ChannelId]) -> Void) {
        database.backgroundReadOnlyContext.perform {
            let request = ChannelDTO.allChannelsFetchRequest
            request.fetchLimit = 1000
            request.propertiesToFetch = ["cid"]
            let channels = (try? self.database.backgroundReadOnlyContext.fetch(request)) ?? []
            completion(channels.compactMap { try? ChannelId(cid: $0.cid) })
        }
    }

    func syncChannelsEvents(
        channelIds: [ChannelId],
        lastSyncAt: Date,
        isRecovery: Bool,
        completion: @escaping (Result<[ChannelId], SyncError>) -> Void
    ) {
        // In recovery mode, `/sync` should always be called.
        // Otherwise, the cooldown is checked.
        guard isRecovery || Date().timeIntervalSince(lastSyncAt) > syncCooldown else {
            completion(.failure(.noNeedToSync))
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
                    self?.updateUserValue({
                        $0?.lastSynchedEventDate = (payload.eventPayloads.last?.createdAt ?? date).bridgeDate
                    }) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(channelIds))
                        }
                    }
                }
            case let .failure(error):
                log.error("Failed synching events: \(error).", subsystems: .offlineSupport)
                guard error.isBackendErrorWith400StatusCode else {
                    completion(.failure(.syncEndpointFailed(error)))
                    return
                }
                // Backend responds with 400 if there were more than 1000 events to return
                // Cleaning local channels data and refetching it from scratch
                log.info("/sync returned too many events. Continuing...", subsystems: .offlineSupport)
                completion(.success([]))
            }
        }

        if isRecoveryRequest {
            apiClient.recoveryRequest(endpoint: endpoint, completion: requestCompletion)
        } else {
            apiClient.request(endpoint: endpoint, completion: requestCompletion)
        }
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
