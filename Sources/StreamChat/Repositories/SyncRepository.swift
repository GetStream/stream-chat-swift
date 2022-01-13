//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

enum SyncError: Error {
    case localStorageDisabled
    case noNeedToSync
    case syncEndpointFailed(Error)
    case resettingQueryFailed(Error)
    case couldNotUpdateUserValue(Error)

    var shouldRetry: Bool {
        switch self {
        case .localStorageDisabled, .noNeedToSync, .couldNotUpdateUserValue:
            return false
        case .syncEndpointFailed, .resettingQueryFailed:
            return true
        }
    }
}

class SyncRepository {
    /// Do not call the sync endpoint more than once every six seconds
    let syncCooldown: TimeInterval = 6.0
    /// Maximum number of retries for each operation step.
    let retriesCount = 2
    let config: ChatClientConfig
    let activeChatListControllers: NSHashTable<ChatChannelListController>
    let channelRepository: ChannelListUpdater
    let eventNotificationCenter: EventNotificationCenter
    let database: DatabaseContainer
    let apiClient: APIClient

    private var lastPendingConnectionDate: Date? {
        get {
            getUserValue { $0?.lastPendingConnectionDate }
        }
        set {
            updateUserValue { $0?.lastPendingConnectionDate = newValue }
        }
    }

    private lazy var operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.name = "com.stream.sync-repository"
        return operationQueue
    }()

    init(
        config: ChatClientConfig,
        activeChatListControllers: NSHashTable<ChatChannelListController>,
        channelRepository: ChannelListUpdater,
        eventNotificationCenter: EventNotificationCenter,
        database: DatabaseContainer,
        apiClient: APIClient
    ) {
        self.config = config
        self.activeChatListControllers = activeChatListControllers
        self.channelRepository = channelRepository
        self.eventNotificationCenter = eventNotificationCenter
        self.database = database
        self.apiClient = apiClient
    }

    func recoverFromOfflineState(completion: @escaping () -> Void) {
        guard config.isLocalStorageEnabled else {
            completion()
            return
        }

        // [Sync and watch channels](https://www.notion.so/2-Sync-and-watch-channels-ac44feb55de3482f8f0f99e100ca40c6)
        //      1. Call `/sync` endpoint and get missing events for all locally existed channels
        //      *** 2. Start watching open channels *** (Not in V1)
        //      3. Refetch channel lists queries, link only what backend returns (the 1st page)
        //      4. Clean up local message history for channels that are outdated/will get outdated
        //      5. Bump the last sync timestamp

        log.info("Starting to recover offline state", subsystems: .offlineSupport)
        var operations: [Operation] = []

        // 0. We get the existing channelIds
        let channelIds = getExistingChannelIds()

        // 1. Call `/sync` endpoint and get missing events for all locally existed channels
        let syncEvents = AsyncOperation(retries: retriesCount) { [weak self] done in
            guard let self = self, let lastPendingConnectionDate = self.lastPendingConnectionDate else {
                done(.continue)
                return
            }

            self.syncMissingEvents(using: lastPendingConnectionDate, channelIds: channelIds) { result in
                if result.error?.shouldRetry == true {
                    done(.retry)
                } else {
                    self.lastPendingConnectionDate = nil
                    done(.continue)
                }
            }
        }
        operations.append(syncEvents)

        // 2. Start watching open channels *** (Not in V1)
        // ***************************************
        // --------------  PENDING ---------------
        // ***************************************

        // 3. Refetch channel lists queries, link only what backend returns (the 1st page)
        let refetchQueryOperations = activeChatListControllers.allObjects.map { controller in
            AsyncOperation(retries: retriesCount) { done in
                self.resetChannelsQuery(for: controller) { result in
                    switch result {
                    case let .success(channels):
                        done(.continue)
                    case let .failure(error):
                        done(error.shouldRetry ? .retry : .continue)
                    }
                }
            }
        }
        operations.append(contentsOf: refetchQueryOperations)

        // 4. Clean up local message history for channels that are outdated/will get outdated
        // ***************************************
        // --------------  PENDING ---------------
        // ***************************************

        // 5. Bump the last sync timestamp
        // ***************************************
        // --------------  PENDING ---------------
        // ***************************************

        // 6. Clean lastPendingConnectionDate and complete
        operations.append(BlockOperation(block: completion))

        // We are making sure the operations happen secuentially one after the other by setting one as the dependency
        // of the following one
        var previousOperation: Operation?
        operations.reversed().forEach { operation in
            defer { previousOperation = operation }
            guard let previousOperation = previousOperation else { return }
            previousOperation.addDependency(operation)
        }

        operationQueue.addOperations(operations, waitUntilFinished: false)
    }

    func updateLastPendingConnectionDate(with date: Date) {
        // If there's a pending connection date, it means there was an issue retrieving all the past events.
        // If that's the case, we keep the existing one.
        guard lastPendingConnectionDate == nil else { return }
        lastPendingConnectionDate = date
    }

    func syncExistingChannelsEvents(completion: @escaping (Result<MissingEventsPayload, SyncError>) -> Void) {
        let lastSyncAt = getUserValue { $0?.lastReceivedEventDate }
        guard let lastSyncAt = lastSyncAt, Date().timeIntervalSince(lastSyncAt) > syncCooldown else {
            completion(.failure(.noNeedToSync))
            return
        }

        let channelIds = getExistingChannelIds()
        syncMissingEvents(using: lastSyncAt, channelIds: channelIds, completion: completion)
    }

    private func syncMissingEvents(
        using date: Date,
        channelIds: [ChannelId],
        completion: @escaping (Result<MissingEventsPayload, SyncError>) -> Void
    ) {
        guard config.isLocalStorageEnabled else {
            completion(.failure(.localStorageDisabled))
            return
        }

        log.info("Synching events for existing channels since \(date)", subsystems: .offlineSupport)
        getMissingEvents(since: date, channelIds: channelIds) { result in
            switch result {
            case let .success(payload):
                self.updateUserValue({
                    $0?.lastReceivedEventDate = payload.eventPayloads.first?.createdAt ?? date
                }) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(payload))
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func resetChannelsQuery(
        for controller: ChatChannelListController,
        completion: @escaping (Result<[ChatChannel], SyncError>) -> Void
    ) {
        log.info("Refetching query for \(controller.query.debugDescription)", subsystems: .offlineSupport)

        // Fetches the channels matching the query, and stores them in the database.
        channelRepository.update(channelListQuery: controller.query) { result in
            switch result {
            case let .success(channels):
                // Resets the query for the controller to only be linked to the controllers that were just fetched from
                // the API
                controller.resetLinkedChannels(to: channels)
                completion(.success(channels))
            case let .failure(error):
                log.error("Failed refetching query for \(controller.query.debugDescription): \(error)", subsystems: .offlineSupport)
                completion(.failure(.resettingQueryFailed(error)))
            }
        }
    }

    private func getMissingEvents(
        since lastSyncDate: Date,
        channelIds: [ChannelId],
        completion: @escaping (Result<MissingEventsPayload, SyncError>) -> Void
    ) {
        let endpoint: Endpoint<MissingEventsPayload> = .missingEvents(since: lastSyncDate, cids: channelIds)

        apiClient.request(endpoint: endpoint) { result in
            switch result {
            case let .success(payload):
                self.eventNotificationCenter.process(
                    payload.eventPayloads.asEvents(),
                    postNotifications: false
                ) {
                    completion(.success(payload))
                }
            case let .failure(error):
                log.error("Failed cleaning up channels data: \(error).", subsystems: .offlineSupport)
                completion(.failure(.syncEndpointFailed(error)))
            }
        }
    }

    private func getExistingChannelIds() -> [ChannelId] {
        let request = ChannelDTO.allChannelsFetchRequest
        request.propertiesToFetch = ["cid"]
        let results = (try? database.viewContext.fetch(request)) ?? []
        let cids = results.compactMap { try? ChannelId(cid: $0.cid) }
        return cids
    }

    private func getUserValue<T>(_ block: (inout CurrentUserDTO?) -> T?) -> T? {
        var value: T?
        database.viewContext.performAndWait {
            var currentUser = self.database.viewContext.currentUser
            value = block(&currentUser)
        }

        return value
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
                completion?(nil)
            }
        }
    }
}
