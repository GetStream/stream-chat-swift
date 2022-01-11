//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

enum SyncError: Error {
    case syncEndpointFailed(Error)
    case couldNotBumpLastSyncDate(Error)
}

class SyncRepository {
    /// Do not call the sync endpoint more than once every six seconds
    let syncCooldown: TimeInterval = 6.0
    let config: ChatClientConfig
    let channelRepository: ChannelListUpdater
    let eventNotificationCenter: EventNotificationCenter
    let database: DatabaseContainer
    let apiClient: APIClient

    private lazy var operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.name = "com.stream.sync-repository"
        return operationQueue
    }()

    init(
        config: ChatClientConfig,
        channelRepository: ChannelListUpdater,
        eventNotificationCenter: EventNotificationCenter,
        database: DatabaseContainer,
        apiClient: APIClient
    ) {
        self.config = config
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

        // A failure here should not stop the next execution, but should clean the db most probably
        syncExistingChannelsEvents(bumpSyncDate: false) {
            // Refetch query
        }
    }

    func syncExistingChannelsEvents(bumpSyncDate: Bool, completion: @escaping () -> Void) {
        guard config.isLocalStorageEnabled else {
            completion()
            return
        }

        let lastSyncAt = obtainLastSyncDate()
        guard let lastSyncAt = lastSyncAt, Date().timeIntervalSince(lastSyncAt) > syncCooldown else {
            completion()
            return
        }

        getEventsSinceLastSync(at: lastSyncAt) { result in
            guard bumpSyncDate, case let .success(payload) = result else {
                completion()
                return
            }
            self.bumpLastSyncDate(lastReceivedEventDate: payload.eventPayloads.first?.createdAt ?? lastSyncAt) { _ in
                completion()
            }
        }
    }

    private func obtainLastSyncDate() -> Date? {
        var lastReceivedEventDate: Date?
        database.viewContext.performAndWait {
            lastReceivedEventDate = self.database.viewContext.currentUser?.lastReceivedEventDate
        }
        return lastReceivedEventDate
    }

    private func bumpLastSyncDate(lastReceivedEventDate: Date, completion: @escaping (SyncError?) -> Void) {
        database.write { session in
            session.currentUser?.lastReceivedEventDate = lastReceivedEventDate
        } completion: { error in
            if let error = error {
                log.error(error)
                completion(.couldNotBumpLastSyncDate(error))
            } else {
                completion(nil)
            }
        }
    }

    private func getEventsSinceLastSync(
        at lastSyncDate: Date,
        completion: @escaping (Result<MissingEventsPayload, SyncError>) -> Void
    ) {
        let cids = getExistingChannelIds()
        let endpoint: Endpoint<MissingEventsPayload> = .missingEvents(since: lastSyncDate, cids: cids)

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
                log.error("Failed cleaning up channels data: \(error).")
                completion(.failure(.syncEndpointFailed(error)))
            }
        }
    }

    private func getExistingChannelIds() -> [ChannelId] {
        let request = ChannelDTO.allChannelsFetchRequest
        request.fetchLimit = 1000
        request.propertiesToFetch = ["cid"]

        let results = (try? database.viewContext.fetch(request)) ?? []
        let cids = results.compactMap { try? ChannelId(cid: $0.cid) }
        return cids
    }
}
