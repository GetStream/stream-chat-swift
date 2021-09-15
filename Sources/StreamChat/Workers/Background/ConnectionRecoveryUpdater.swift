//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// The type is designed to obtain missing events that happened in watched channels while user
/// was not connected to the web-socket.
///
/// The object listens for `ConnectionStatusUpdated` events and when the status becomes `connected` the `/sync` endpoint is called
/// with `lastSyncedAt` and `cids` of locally existed channels linked to at least one query.
///
/// Case 1:
/// If `/sync` succeds and returns events, channel list queries are re-fetched considering all locally existed channels as synced.
/// If re-fetch succeeds, `lastSyncedAt` is set to most recent event timestamp (received from `/sync`).
/// If re-fetch fails, `lastSyncedAt` stays the same.
///
/// Case 2:
/// If `/sync` succeds and returns zero events, channel list queries are re-fetched considering all locally existed channels as synced.
/// If re-fetch succeeds, `lastSyncedAt` is set to current date.
/// If re-fetch fails, `lastSyncedAt` stays the same.
///
/// Case 3:
/// If `/sync` fails with error, channel list queries are re-fetched considering all locally existed channels as out of sync.
/// If re-fetch succeeds, `lastSyncedAt` is set to current date otherwise.
/// If re-fetch fails, `lastSyncedAt` stays the same.
///
/// If `ConnectionRecoveryUpdater` is created with `useSyncEndpoint == false`, the connection recovery logic behaves as
/// described in `Case 3`.
///
class ConnectionRecoveryUpdater: EventWorker {
    // MARK: - Properties
    
    private var connectionObserver: EventObserver?
    private let databaseCleanupUpdater: DatabaseCleanupUpdater
    private let useSyncEndpoint: Bool
    
    // MARK: - Init

    override init(
        database: DatabaseContainer,
        eventNotificationCenter: EventNotificationCenter,
        apiClient: APIClient
    ) {
        useSyncEndpoint = false
        databaseCleanupUpdater = DatabaseCleanupUpdater(database: database, apiClient: apiClient)
        super.init(
            database: database,
            eventNotificationCenter: eventNotificationCenter,
            apiClient: apiClient
        )
        startObserving()
    }
    
    init(
        database: DatabaseContainer,
        eventNotificationCenter: EventNotificationCenter,
        apiClient: APIClient,
        useSyncEndpoint: Bool
    ) {
        databaseCleanupUpdater = DatabaseCleanupUpdater(database: database, apiClient: apiClient)
        self.useSyncEndpoint = useSyncEndpoint
        super.init(
            database: database,
            eventNotificationCenter: eventNotificationCenter,
            apiClient: apiClient
        )
        startObserving()
    }
    
    init(
        database: DatabaseContainer,
        eventNotificationCenter: EventNotificationCenter,
        apiClient: APIClient,
        databaseCleanupUpdater: DatabaseCleanupUpdater,
        useSyncEndpoint: Bool
    ) {
        self.databaseCleanupUpdater = databaseCleanupUpdater
        self.useSyncEndpoint = useSyncEndpoint
        super.init(
            database: database,
            eventNotificationCenter: eventNotificationCenter,
            apiClient: apiClient
        )
        startObserving()
    }
    
    // MARK: - Private
    
    private func startObserving() {
        connectionObserver = EventObserver(
            notificationCenter: eventNotificationCenter,
            transform: { $0 as? ConnectionStatusUpdated },
            callback: { [weak self] in
                guard let self = self else {
                    log.warning("Callback called while self is nil")
                    return
                }

                switch $0.webSocketConnectionState {
                case .connected:
                    self.fetchAndReplayMissingEvents()
                default:
                    break
                }
            }
        )
    }
    
    private func fetchAndReplayMissingEvents() {
        database.write { [weak self, useSyncEndpoint] session in
            guard let currentUser = session.currentUser else {
                log.error("In `connected` state current user must exist in database")
                return
            }
            
            guard let lastSyncedAt = currentUser.lastSyncedAt else {
                log.debug("There's no previous session, remembering the current date as last sync date")
                currentUser.lastSyncedAt = Date()
                return
            }
            
            guard useSyncEndpoint else {
                log.debug("Ignore `/sync` and re-fetch local queries")
                self?.refetchLocalQueries()
                return
            }
            
            let queriesRequest = NSFetchRequest<ChannelListQueryDTO>(entityName: ChannelListQueryDTO.entityName)
            let queries = (try? (session as! NSManagedObjectContext).fetch(queriesRequest)) ?? []
            let cids = Set(
                queries
                    .flatMap(\.channels)
                    .compactMap { try? ChannelId(cid: $0.cid) }
                    .prefix(1000)
            )
            
            self?.getMissingEvents(for: cids, since: lastSyncedAt) {
                switch $0 {
                case let .success(payload):
                    let mostRecentEventTimestamp = payload
                        .eventPayloads
                        .compactMap(\.createdAt)
                        .sorted()
                        .last
                    
                    self?.refetchLocalQueries(
                        syncedChannelIDs: cids,
                        bumpLastSyncDateTo: mostRecentEventTimestamp ?? lastSyncedAt
                    )
                case .failure:
                    self?.refetchLocalQueries()
                }
            }
        }
    }
    
    private func getMissingEvents(
        for cids: Set<ChannelId>,
        since lastSyncedAt: Date,
        completion: @escaping (Result<MissingEventsPayload, Error>) -> Void
    ) {
        log.debug("Will fetch missing events for \(cids) starting from \(lastSyncedAt)")
        
        apiClient.request(
            endpoint: .missingEvents(since: lastSyncedAt, cids: .init(cids))
        ) { [weak self] in
            switch $0 {
            case let .success(payload):
                log.debug("Did receive \(payload.eventPayloads.count) missing events: \(payload.eventPayloads)")
                
                self?.eventNotificationCenter.feedEventsToMiddlewares(
                    payload.eventPayloads.compactMap { try? $0.event() },
                    shouldPostEvents: false
                ) {
                    completion(.success(payload))
                }
            case let .failure(error):
                log.debug("Fail to get missing events: \(error)")
                
                completion(.failure(error))
            }
        }
    }
    
    private func refetchLocalQueries(
        syncedChannelIDs: Set<ChannelId> = [],
        bumpLastSyncDateTo newValue: Date = Date()
    ) {
        databaseCleanupUpdater.syncChannelListQueries(
            syncedChannelIDs: syncedChannelIDs
        ) { [weak self] in
            switch $0 {
            case .success:
                self?.database.write { session in
                    log.debug("Bumping `lastSyncedAt` to \(newValue)")
                    
                    session.currentUser?.lastSyncedAt = newValue
                }
            case let .failure(error):
                log.error("Channel list queries re-fetch has failed: \(error)")
            }
        }
    }
}

private extension Error {
    /// Backend responds with 400 if there was more than 1000 events to replay
    var isTooManyMissingEventsToSyncError: Bool {
        isBackendErrorWith400StatusCode
    }
}
