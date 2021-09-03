//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// The type is designed to obtain missing events that happened in watched channels while user
/// was not connected to the web-socket.
///
/// The object listens for `ConnectionStatusUpdated` events
/// and remembers the `CurrentUserDTO.lastReceivedEventDate` when status becomes `connecting`.
///
/// When the status becomes `connected` the `/sync` endpoint is called
/// with `lastReceivedEventDate` and `cids` of watched channels.
///
/// We remember `lastReceivedEventDate` when state becomes `connecting` to catch the last event date
/// before the `HealthCheck` override the `lastReceivedEventDate` with the recent date.
///
class ConnectionRecoveryUpdater: EventWorker {
    // MARK: - Properties
    
    private var connectionObserver: EventObserver?
    private let databaseCleanupUpdater: DatabaseCleanupUpdater
    @Atomic private var lastSyncedAt: Date?
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
            callback: { [unowned self] in
                switch $0.webSocketConnectionState {
                case .connecting:
                    self.obtainLastSyncDate()
                case .connected:
                    fetchAndReplayMissingEvents()
                default:
                    break
                }
            }
        )
    }
    
    private func obtainLastSyncDate() {
        let context = database.backgroundReadOnlyContext
        context.perform { [weak self] in
            self?.lastSyncedAt = context.currentUser?.lastReceivedEventDate
        }
    }
    
    private func fetchAndReplayMissingEvents() {
        let context = database.backgroundReadOnlyContext
        context.perform { [weak self] in
            guard let lastSyncedAt = self?.lastSyncedAt else { return }
            
            if self?.useSyncEndpoint == true {
                let cids = Set(
                    context
                        .loadChannelListQueries()
                        .flatMap(\.channels)
                        .map(\.channelId)
                        .prefix(1000)
                )
                
                self?.getMissingEvents(for: cids, since: lastSyncedAt) { error in
                    self?.databaseCleanupUpdater.syncChannelListQueries(
                        syncedChannelIDs: error == nil ? cids : []
                    )
                }
            } else {
                self?.databaseCleanupUpdater.syncChannelListQueries(syncedChannelIDs: [])
            }
        }
    }
    
    private func getMissingEvents(
        for cids: Set<ChannelId>,
        since lastSyncedAt: Date,
        completion: @escaping (Error?) -> Void
    ) {
        log.debug("Will fetch missing events for \(cids) starting from \(lastSyncedAt)")
        
        apiClient.request(
            endpoint: .missingEvents(since: lastSyncedAt, cids: .init(cids))
        ) { [weak self] in
            switch $0 {
            case let .success(payload):
                log.debug("Did receive \(payload.eventPayloads.count) missing events: \(payload.eventPayloads)")
                
                self?.eventNotificationCenter.process(payload.eventPayloads) {
                    completion(nil)
                }
            case let .failure(error):
                log.debug("Fail to get missing events: \(error)")
                
                completion(error)
            }
        }
    }
}

// MARK: - Extensions

extension EventNotificationCenter {
    /// The method is used to convert incoming event payloads into events and calls `process(_:)` for each event
    /// that was successfully decoded.
    ///
    /// - Parameter payloads: The event payloads
    func process(_ payloads: [EventPayload], completion: (() -> Void)? = nil) {
        payloads.forEach {
            do {
                process(try $0.event())
            } catch {
                log.error("Failed to transform a payload into an event: \($0)")
            }
        }
        completion?()
    }
}

private extension Error {
    /// Backend responds with 400 if there was more than 1000 events to replay
    var isTooManyMissingEventsToSyncError: Bool {
        isBackendErrorWith400StatusCode
    }
}
