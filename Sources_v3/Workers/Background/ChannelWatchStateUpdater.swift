//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData

/// After WebSocket changes it's state to `connected` we need to start watching existing channels so we can receive updated on them.
/// This background worker listents to `ConnectionStatusUpdated` event and on `connected` we are fetching all channels from DB and
/// sending ChannelListQuery to backend to start `watching` channels.
final class ChannelWatchStateUpdater<ExtraData: ExtraDataTypes>: Worker {
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
    
    override init(database: DatabaseContainer, webSocketClient: WebSocketClient, apiClient: APIClient) {
        super.init(database: database, webSocketClient: webSocketClient, apiClient: apiClient)
        startObserving()
    }
    
    private func startObserving() {
        webSocketConnectedObserver = WebSocketConnectedObserver(
            notificationCenter: webSocketClient.eventNotificationCenter,
            filter: { $0.connectionStatus == .connected },
            callback: { [unowned self] in self.watchChannels() }
        )
    }
    
    private func watchChannels() {
        database.backgroundReadOnlyContext.perform { [weak self] in
            guard let channels = self?.channels else { return }
            
            let channelIds = channels.map(\.cid)
            guard !channelIds.isEmpty else { return }
            let channelListQuery = ChannelListQuery(
                filter: .in("cid", channelIds),
                pagination: [.limit(1)],
                options: [.watch]
            )
            
            self?.apiClient.request(
                endpoint: .channels(query: channelListQuery),
                completion: { (result: Result<ChannelListPayload<ExtraData>, Error>) in
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
