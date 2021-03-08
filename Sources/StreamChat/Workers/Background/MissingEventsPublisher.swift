//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// The type is designed to obtain missing events that happened in watched channels while user
/// was not connected to the web-socket.
///
/// The object listenes for `ConnectionStatusUpdated` events
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
    @Atomic private var lastSyncedAt: Date?
    
    // MARK: - Init

    override init(
        database: DatabaseContainer,
        eventNotificationCenter: EventNotificationCenter,
        apiClient: APIClient
    ) {
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
            self?.lastSyncedAt = self?.database.backgroundReadOnlyContext.currentUser()?.lastReceivedEventDate
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
                    self?.eventNotificationCenter.process(payload.eventPayloads)
                case let .failure(error):
                    log.error("Internal error: Failed to fetch and reply missing events: \(error)")
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
