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
    let syncCooldown: TimeInterval = 6.0
    /// Maximum number of retries for each operation step.
    let maxRetriesCount = 2
    let config: ChatClientConfig
    let activeChannelControllers: NSHashTable<ChatChannelController>
    let activeChannelListControllers: NSHashTable<ChatChannelListController>
    let channelRepository: ChannelListUpdater
    let offlineRequestsRepository: OfflineRequestsRepository
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

    /// Syncs the local state with the server to make sure the local database is up to date.
    /// It features queuing, serialization and retries
    ///
    /// [Sync and watch channels](https://www.notion.so/2-Sync-and-watch-channels-ac44feb55de3482f8f0f99e100ca40c6)
    /// 1. Call `/sync` endpoint and get missing events for all locally existed channels
    /// 2. Start watching open channels
    /// 3. Refetch channel lists queries, link only what backend returns (the 1st page)
    /// 4. Clean up local message history for channels that are outdated/will get outdated
    /// 5. Run offline actions requests
    /// 6. Bump the last sync timestamp
    ///
    /// - Parameter completion: A block that will get executed upon completion of the synchronization
    func syncLocalState(completion: @escaping () -> Void) {
        guard config.isLocalStorageEnabled else {
            completion()
            return
        }
        operationQueue.cancelAllOperations()

        log.info("Starting to recover offline state", subsystems: .offlineSupport)
        let context = SyncContext()
        context.lastConnectionDate = lastConnection
        var operations: [Operation] = []

        // Enter recovery mode so no other requests are triggered.
        apiClient.enterRecoveryMode()

        // Get the existing channelIds
        operations.append(GetChannelIdsOperation(database: database, context: context))
        // Get pending connection date
        operations.append(GetPendingConnectionDateOperation(database: database, context: context))

        // 1. Call `/sync` endpoint and get missing events for all locally existed channels
        operations.append(SyncEventsOperation(database: database, syncRepository: self, context: context))

        // 2. Start watching open channels.
        let watchChannelOperations: [AsyncOperation] = activeChannelControllers.allObjects.map { controller in
            WatchChannelOperation(controller: controller, context: context)
        }
        operations.append(contentsOf: watchChannelOperations)

        // 3. Refetch channel lists queries, link only what backend returns (the 1st page)
        // 4. Clean up local message history for channels that are outdated/will get outdated
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

        // 5. Run offline actions requests
        operations.append(ExecutePendingOfflineActions(offlineRequestsRepository: offlineRequestsRepository))

        // 6. Bump the last sync timestamp
        operations.append(AsyncOperation { [weak self] _, done in
            log.info("6. Bump the last sync timestamp", subsystems: .offlineSupport)
            self?.updateUserValue { user in
                user?.lastSyncAt = Date()
            } completion: { _ in
                done(.continue)
            }
        })

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

    /// Receives a date when the connection has been stablished
    /// It updates user's lastPendingConnectionDate if there's no other pending date. If there is another pending date, this date passed as parameter is stored in
    /// memory for this class to use it when needed
    /// - Parameter date: Date of the connection
    func updateLastConnectionDate(with date: Date, completion: ((SyncError?) -> Void)? = nil) {
        // We store the last connection date in memory.
        lastConnection = date
        updateUserValue({ user in
            // If there's a pending connection date, it means there was an issue retrieving all the past events.
            // If that's the case, we keep the existing one.
            guard let user = user, user.lastPendingConnectionDate == nil else { return }
            log.info("Updating last pending connection date", subsystems: .offlineSupport)
            user.lastPendingConnectionDate = date
        }, completion: completion)
    }

    /// Syncs the events for the active chat channels using the last sync date.
    /// - Parameter completion: A block that will get executed upon completion of the synchronization
    func syncExistingChannelsEvents(completion: @escaping (Result<[ChannelId], SyncError>) -> Void) {
        let syncCooldown = self.syncCooldown
        getUser { [weak self] user in
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

            let request = ChannelDTO.allChannelsFetchRequest
            request.fetchLimit = 1000
            request.propertiesToFetch = ["cid"]

            self?.getChannelIds { channelIds in
                self?.syncMissingEvents(
                    using: lastSyncAt,
                    channelIds: channelIds,
                    bumpLastSync: true,
                    isRecoveryRequest: false,
                    completion: completion
                )
            }
        }
    }

    private func getUser(completion: @escaping (CurrentUserDTO?) -> Void) {
        var user: CurrentUserDTO?
        database.backgroundReadOnlyContext.perform {
            user = self.database.backgroundReadOnlyContext.currentUser
            completion(user)
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

    func syncMissingEvents(
        using date: Date,
        channelIds: [ChannelId],
        bumpLastSync: Bool,
        isRecoveryRequest: Bool,
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
        getMissingEvents(since: date, channelIds: channelIds, isRecoveryRequest: isRecoveryRequest) { [weak self] result in
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
                // Backend responds with 400 if there were more than 1000 events to return
                // Cleaning local channels data and refetching it from scratch
                log.info("/sync returned too many events. Continuing...", subsystems: .offlineSupport)
                completion(.success([]))
            }
        }
    }

    private func getMissingEvents(
        since lastSyncDate: Date,
        channelIds: [ChannelId],
        isRecoveryRequest: Bool,
        completion: @escaping (Result<MissingEventsPayload, SyncError>) -> Void
    ) {
        let endpoint: Endpoint<MissingEventsPayload> = .missingEvents(since: lastSyncDate, cids: channelIds)
        let requestCompletion: (Result<MissingEventsPayload, Error>) -> Void = { [weak self] result in
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

        if isRecoveryRequest {
            apiClient.recoveryRequest(endpoint: endpoint, completion: requestCompletion)
        } else {
            apiClient.request(endpoint: endpoint, completion: requestCompletion)
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
