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
class MissingEventsPublisher<ExtraData: ExtraDataTypes>: EventWorker {
    // MARK: - Properties
    
    private var connectionObserver: EventObserver?
    private let databaseCleanupUpdater: DatabaseCleanupUpdater<ExtraData>
    @Atomic private var lastSyncedAt: Date?
    
    // MARK: - Init

    override init(
        database: DatabaseContainer,
        eventNotificationCenter: EventNotificationCenter,
        apiClient: APIClient
    ) {
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
        databaseCleanupUpdater: DatabaseCleanupUpdater<ExtraData>
    ) {
        self.databaseCleanupUpdater = databaseCleanupUpdater
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
        database.backgroundReadOnlyContext.perform { [weak self] in
            guard let lastSyncedAt = self?.lastSyncedAt,
                  let allChannels = self?.allChannels else { return }
            
            let watchedChannelIDs = allChannels.map(\.cid).compactMap { try? ChannelId(cid: $0) }
            
            guard !watchedChannelIDs.isEmpty else {
                log.info("Skipping `/sync` endpoint call as there are no channels to watch.")
                return
            }
            
            let endpoint: Endpoint<MissingEventsPayload<ExtraData>> = .missingEvents(
                since: lastSyncedAt,
                cids: watchedChannelIDs
            )
            
            self?.apiClient.request(endpoint: endpoint) {
                switch $0 {
                case let .success(payload):
                    // The sync call was successful.
                    // We schedule all events for existing channels for processing...
                    self?.eventNotificationCenter.process(payload.eventPayloads)

                    // ... and refetch the existing queries to see if there are some new channels
                    self?.databaseCleanupUpdater.refetchExistingChannelListQueries()

                case let .failure(error):
                    log.info("""
                    Backend couldn't handle replaying missing events - there was too many (>1000) events to replay. \
                    Cleaning local channels data and refetching it from scratch
                    """)

                    if error.isTooManyMissingEventsToSyncError {
                        // The sync call failed...
                        self?.database.write {
                            // First we need to clean up existing data
                            try self?.databaseCleanupUpdater.resetExistingChannelsData(session: $0)
                        } completion: { error in
                            if let error = error {
                                log.error("Failed cleaning up channels data: \(error).")
                                return
                            }
                            // Then we have to refetch existing channel list queries
                            self?.databaseCleanupUpdater.refetchExistingChannelListQueries()
                        }
                    }
                }
            }
        }
    }
    
    private var allChannels: [ChannelDTO] {
        do {
            return try database.backgroundReadOnlyContext.fetch(ChannelDTO.allChannelsFetchRequest)
        } catch {
            log.error("Internal error: Failed to fetch [ChannelDTO]: \(error)")
            return []
        }
    }
}

// MARK: - Extensions

private extension EventNotificationCenter {
    /// The method is used to convert incoming event payloads into events and calls `process(_:)` for each event
    /// that was successfully decoded.
    ///
    /// - Parameter payloads: The event payloads
    func process<ExtraData: ExtraDataTypes>(_ payloads: [EventPayload<ExtraData>]) {
        payloads.forEach {
            do {
                process(try $0.event())
            } catch {
                log.error("Failed to transform a payload into an event: \($0)")
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
