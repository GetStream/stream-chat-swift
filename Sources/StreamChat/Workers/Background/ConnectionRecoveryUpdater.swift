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
class ConnectionRecoveryUpdater {
    // MARK: - Properties
    
    private let database: DatabaseContainer
    private let eventNotificationCenter: EventNotificationCenter
    private let apiClient: APIClient
    private var connectionObserver: EventObserver?
    private let databaseCleanupUpdater: DatabaseCleanupUpdater
    @Atomic private var lastSyncedAt: Date?
    private let useSyncEndpoint: Bool
    
    // MARK: - Init
    
    init(
        database: DatabaseContainer,
        eventNotificationCenter: EventNotificationCenter,
        apiClient: APIClient,
        databaseCleanupUpdater: DatabaseCleanupUpdater,
        useSyncEndpoint: Bool
    ) {
        self.database = database
        self.eventNotificationCenter = eventNotificationCenter
        self.apiClient = apiClient
        self.databaseCleanupUpdater = databaseCleanupUpdater
        self.useSyncEndpoint = useSyncEndpoint

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
                case .connecting:
                    self.obtainLastSyncDate()
                case .connected:
                    self.fetchAndReplayMissingEvents()
                default:
                    break
                }
            }
        )
    }
    
    private func obtainLastSyncDate() {
        database.backgroundReadOnlyContext.perform { [weak self] in
            self?.lastSyncedAt = self?.database.backgroundReadOnlyContext.currentUser?.lastReceivedEventDate
        }
    }
    
    private func fetchAndReplayMissingEvents() {
        database.backgroundReadOnlyContext.perform { [weak self, useSyncEndpoint] in
            let refetchExistingQueries: () -> Void = {
                self?.databaseCleanupUpdater.refetchExistingChannelListQueries()
            }
            
            if useSyncEndpoint {
                self?.sync(completion: refetchExistingQueries)
            } else {
                refetchExistingQueries()
            }
        }
    }

    private func sync(completion: @escaping () -> Void) {
        guard let lastSyncedAt = lastSyncedAt else { return }
        
        let watchedChannelIDs = allChannels.map(\.cid).compactMap { try? ChannelId(cid: $0) }
        
        guard !watchedChannelIDs.isEmpty else {
            log.info("Skipping `/sync` endpoint call as there are no channels to watch.")
            return
        }
        
        let endpoint: Endpoint<MissingEventsPayload> = .missingEvents(
            since: lastSyncedAt,
            cids: watchedChannelIDs
        )
        
        apiClient.request(endpoint: endpoint) { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case let .success(payload):
                // The sync call was successful.
                // We schedule all events for existing channels for processing...
                self.eventNotificationCenter.process(
                    payload.eventPayloads.asEvents(),
                    postNotifications: false,
                    completion: completion
                )
                
            case let .failure(error):
                log.info(
                    """
                    Backend couldn't handle replaying missing events - there was too many (>1000) events to replay. \
                    Cleaning local channels data and refetching it from scratch
                    """
                )
                
                if error.isTooManyMissingEventsToSyncError {
                    // The sync call failed...
                    self.database.write {
                        // First we need to clean up existing data
                        try self.databaseCleanupUpdater.resetExistingChannelsData(session: $0)
                    } completion: { error in
                        if let error = error {
                            log.error("Failed cleaning up channels data: \(error).")
                            return
                        }
                        // Then we have to refetch existing channel list queries
                        completion()
                    }
                }
            }
        }
    }
    
    private var allChannels: [ChannelDTO] {
        do {
            let request = ChannelDTO.allChannelsFetchRequest
            request.fetchLimit = 1000
            return try database.backgroundReadOnlyContext.fetch(request)
        } catch {
            log.error("Internal error: Failed to fetch [ChannelDTO]: \(error)")
            return []
        }
    }
}

private extension Error {
    /// Backend responds with 400 if there was more than 1000 events to replay
    var isTooManyMissingEventsToSyncError: Bool {
        isBackendErrorWith400StatusCode
    }
}
