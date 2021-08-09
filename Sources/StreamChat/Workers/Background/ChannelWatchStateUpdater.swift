//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData

/// After WebSocket changes it's state to `connected` we need to start watching existing channels so we can receive updates on them.
/// This background worker listens to `ConnectionStatusUpdated` event and on `connected` we are fetching all channels from DB and
/// sending ChannelListQuery to the backend to start `watching` channels.
final class ChannelWatchStateUpdater: EventWorker {
    private var webSocketConnectedObserver: WebSocketConnectedObserver?
    
    private var channels: [ChannelDTO] {
        do {
            let channels = try database.backgroundReadOnlyContext
                .fetch(NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName))
            return channels
        } catch {
            log.error("Internal error: Failed to fetch [ChannelDTO]: \(error)")
        }
        return []
    }
    
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
    
    private func startObserving() {
        webSocketConnectedObserver = WebSocketConnectedObserver(
            notificationCenter: eventNotificationCenter,
            filter: { $0.connectionStatus == .connected },
            callback: { [unowned self] in self.watchChannels() }
        )
    }
    
    private func watchChannels() {
        database.backgroundReadOnlyContext.perform { [weak self] in
            guard let channels = self?.channels else { return }
            
            let channelIds: [ChannelId] = channels.map(\.cid).compactMap {
                do {
                    return try ChannelId(cid: $0)
                } catch {
                    log.error("Failed to decode `ChannelId` from \($0).")
                    return nil
                }
            }
            
            guard !channelIds.isEmpty else { return }
            
            let channelListQuery = ChannelListQuery(
                filter: .in(.cid, values: channelIds),
                pageSize: 1
            )
            
            self?.apiClient.request(
                endpoint: .channels(query: channelListQuery),
                completion: { (result: Result<ChannelListPayload, Error>) in
                    guard case let .failure(error) = result else { return }
                    log.error("Internal error: failed to update watching state of existing channels: \(error)")
                }
            )
        }
    }
    
    private class WebSocketConnectedObserver: EventObserver {
        init(
            notificationCenter: NotificationCenter,
            filter: @escaping (ConnectionStatusUpdated) -> Bool,
            callback: @escaping () -> Void
        ) {
            super.init(notificationCenter: notificationCenter, transform: { ($0 as? ConnectionStatusUpdated) }) {
                guard filter($0) else { return }
                callback()
            }
        }
    }
}
