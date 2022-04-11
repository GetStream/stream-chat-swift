//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

enum SyncError: Error {
    case localStorageDisabled
    case noNeedToSync
    case tooManyEvents(Error)
    case syncEndpointFailed(Error)
    case couldNotUpdateUserValue(Error)
    case failedFetchingChannels

    var shouldRetry: Bool {
        switch self {
        case .localStorageDisabled, .noNeedToSync, .tooManyEvents, .couldNotUpdateUserValue:
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
    let activeChannelControllers: NSHashTable<ChatChannelController>
    let activeChannelListControllers: NSHashTable<ChatChannelListController>
    let channelRepository: ChannelListUpdater
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
        activeChannelControllers: NSHashTable<ChatChannelController>,
        activeChannelListControllers: NSHashTable<ChatChannelListController>,
        channelRepository: ChannelListUpdater,
        offlineRequestsRepository: OfflineRequestsRepository,
        eventNotificationCenter: EventNotificationCenter,
        database: DatabaseContainer,
        apiClient: APIClient
    ) {
        self.config = config
        self.activeChannelControllers = activeChannelControllers
        self.activeChannelListControllers = activeChannelListControllers
        self.channelRepository = channelRepository
        self.offlineRequestsRepository = offlineRequestsRepository
        self.eventNotificationCenter = eventNotificationCenter
        self.database = database
        self.apiClient = apiClient
    }
    
    deinit {
        operationQueue.cancelAllOperations()
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
    func syncLocalState(completion: @escaping () -> Void) {
        // TODO: this func shouldn't run during login (if the new user == previous user or we're just starting up)
        
        operationQueue.cancelAllOperations()

        log.info("Starting to recover offline state", subsystems: .offlineSupport)
        let context = SyncContext()
        var operations: [Operation] = []

        // Enter recovery mode so no other requests are triggered.
        apiClient.enterRecoveryMode()

        // Get the existing channelIds
        operations.append(GetChannelIdsOperation(database: database, context: context))

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
                    channelRepository: channelRepository,
                    context: context
                )
            }
        operations.append(contentsOf: refetchChannelListQueryOperations)

        // 4. Clean up unwanted channels
        operations.append(CleanUnwantedChannelsOperation(database: database, context: context))

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
        getChannelIds { [weak self] channelIds in
            self?.syncChannelsEvents(channelIds: channelIds, isRecovery: false, completion: completion)
        }
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
        isRecovery: Bool,
        completion: @escaping (Result<[ChannelId], SyncError>) -> Void
    ) {
        guard !channelIds.isEmpty else {
            completion(.success([]))
            return
        }

        let syncCooldown = self.syncCooldown
        getUser { [weak self] user in
            guard let lastSyncAt = user?.lastSynchedEventDate else {
                // That's the first session of the current user. Bump `lastSyncAt` with current time and return.
                self?.updateUserValue({
                    $0?.lastSynchedEventDate = Date()
                }, completion: { _ in
                    completion(.failure(.noNeedToSync))
                })
                return
            }

            guard Date().timeIntervalSince(lastSyncAt) > syncCooldown else {
                completion(.failure(.noNeedToSync))
                return
            }

            self?.syncMissingEvents(
                using: lastSyncAt,
                channelIds: channelIds,
                isRecoveryRequest: isRecovery,
                completion: completion
            )
        }
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
        let endpoint: Endpoint<MissingEventsPayload> = .missingEvents(since: date, cids: channelIds)
        let requestCompletion: (Result<MissingEventsPayload, Error>) -> Void = { [weak self] result in
            switch result {
            case let .success(payload):
                log.info("Processing pending events. Count \(payload.eventPayloads.count)", subsystems: .offlineSupport)
                self?.processMissingEventsPayload(payload) {
                    self?.updateUserValue({ $0?.lastSynchedEventDate = payload.eventPayloads.last?.createdAt ?? date }) { error in
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
