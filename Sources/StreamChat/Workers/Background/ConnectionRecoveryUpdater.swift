//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// The type is designed to obtain missing events that happened in watched channels while user
/// was not connected to the web-socket.
///
/// The object listens for `ConnectionStatusUpdated` events
/// and remembers the `CurrentUserDTO.lastSyncedAt` when status becomes `connecting`.
///
/// When the status becomes `connected` the `/sync` endpoint is called
/// with `lastSyncedAt` and `cids` of watched channels.
///
/// We remember `lastSyncedAt` when state becomes `connecting` to catch the last event date
/// before the `HealthCheck` override the `lastSyncedAt` with the recent date.
///
class ConnectionRecoveryUpdater {
    // MARK: - Properties
    
    private unowned var client: ChatClient
    
    @Atomic private var _activeChannelListRefs = NSHashTable<AnyObject>.weakObjects()
    var activeChannelListControllers: [ChatChannelListController] {
        _activeChannelListRefs.allObjects.compactMap { $0 as? ChatChannelListController }
    }
    
    @Atomic private var _activeChannelRefs = NSHashTable<AnyObject>.weakObjects()
    var activeChannelControllers: [ChatChannelController] {
        _activeChannelRefs.allObjects.compactMap { $0 as? ChatChannelController }
    }
    
    // MARK: - Component registration
    
    func register(_ controller: ChatChannelListController) {
        __activeChannelListRefs.mutate { $0.add(controller) }
    }
    
    func register(_ controller: ChatChannelController) {
        __activeChannelRefs.mutate { $0.add(controller) }
    }
    
    // MARK: - Init
    
    init(client: ChatClient) {
        self.client = client
        
        subscribeOnNotifications()
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    // MARK: - Subscriptions
    
    private func subscribeOnNotifications() {
        client.backgroundTaskScheduler?.startListeningForAppStateUpdates(
            onEnteringBackground: { [weak self] in self?.handleAppDidEnterBackground() },
            onEnteringForeground: { [weak self] in self?.handleAppDidBecomeActive() }
        )
        
        client.eventNotificationCenter.addObserver(
            self,
            selector: #selector(didChangeInternetConnectionStatus(_:)),
            name: .internetConnectionStatusDidChange,
            object: nil
        )
    }
    
    private func unsubscribeFromNotifications() {
        client.backgroundTaskScheduler?.stopListeningForAppStateUpdates()
        
        client.eventNotificationCenter.removeObserver(
            self,
            name: .internetConnectionStatusDidChange,
            object: nil
        )
    }
    
    // MARK: - Notification handlers
    
    private func handleAppDidBecomeActive() {
        client.backgroundTaskScheduler?.endTask()
        
        reconnectIfNeeded()
    }
    
    private func handleAppDidEnterBackground() {
        // We can't disconnect if we're not connected
        guard client.connectionStatus == .connected else {
            return
        }
        
        guard client.config.staysConnectedInBackground else {
            // We immediately disconnect
            client.clientUpdater.disconnect(source: .systemInitiated)
            return
        }
        
        guard let scheduler = client.backgroundTaskScheduler else { return }
        
        let succeed = scheduler.beginTask { [weak self] in
            self?.client.clientUpdater.disconnect(source: .systemInitiated)
        }
        
        if !succeed {
            // Can't initiate a background task, close the connection
            client.clientUpdater.disconnect(source: .systemInitiated)
        }
    }

    @objc private func didChangeInternetConnectionStatus(_ notification: Notification) {
        switch (client.connectionStatus, notification.internetConnectionStatus?.isAvailable) {
        case (.connected, false):
            client.clientUpdater.disconnect(source: .systemInitiated)
        case (.disconnected, true):
            reconnectIfNeeded()
        default:
            return
        }
    }
    
    // MARK: - Reconnection
    
    private func reconnectIfNeeded() {
        guard client.userConnectionProvider != nil else {
            // The client has not been connected yet during this session
            return
        }
                
        guard client.webSocketClient?.connectionState.shouldAutomaticallyReconnect == true else {
            // We should not reconnect automatically
            return
        }
        
        guard client.internetConnection.status.isAvailable else {
            // We are offline. Once the connection comes back we will try to reconnect again
            return
        }
        
        // 1. Establish web-socket connection, no `channel` events will come as we don't watch any queries/channels yet
        client.clientUpdater.connect { [weak self] in
            guard $0 == nil else {
                log.error("Failed to establuish web-socket connection: \($0?.localizedDescription ?? "")")
                return
            }
            
            // 2. Get channel and last sync date from database
            self?.loadSyncData {
                guard case .success(let (cidsToSync, lastSyncAt)) = $0 else {
                    log.error("Failed to get data for sync from the database: \($0.error?.localizedDescription ?? "")")
                    return
                }
                
                // 3. Get missing events for channels since the given date
                self?.fetchAndSaveMissingEvents(for: cidsToSync, since: lastSyncAt) {
                    guard case .success(let (syncedCIDs, mostRecentEventDate)) = $0 else {
                        log.error("Failed to get missing events for channels: \($0.error?.localizedDescription ?? "")")
                        return
                    }
                        
                    // 4. Start watching active channels
                    self?.syncActiveChannels(syncedCIDs: syncedCIDs) {
                        guard $0.compactMap({ _, error in error }).isEmpty else {
                            log.error("Failed to to sync one or more active channels: \($0)")
                            return
                        }
                                                
                        // 5. Start watching active channel list queries
                        self?.syncChannelListQueries(syncedCIDs: syncedCIDs.union($0.compactMap(\.0.cid))) {
                            guard $0.compactMap({ _, error in error }).isEmpty else {
                                log.error("Failed to to sync one or more active channel list queries: \($0)")
                                return
                            }
                            
                            // 6. Update last sync date since all missing events were applied
                            self?.bumpLastSyncDate(mostRecentEventDate) {
                                log.info("Active channels and channel list queries are up-to-date.")
                            }
                        }
                    }
                }
            }
        }
    }
}

private extension ConnectionRecoveryUpdater {
    func loadSyncData(completion: @escaping (Result<(Set<ChannelId>, Date), Error>) -> Void) {
        client.databaseContainer.write { session in
            guard let currentUser = session.currentUser else {
                completion(.failure(ClientError.CurrentUserDoesNotExist()))
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
            
            completion(.success((cids, currentUser.lastSyncedAt)))
        }
    }
    
    func fetchAndSaveMissingEvents(
        for cids: Set<ChannelId>,
        since lastSyncedAt: Date,
        completion: @escaping (Result<(Set<ChannelId>, Date), Error>) -> Void
    ) {
        guard !cids.isEmpty else {
            completion(.success((cids, lastSyncedAt)))
            return
        }
        
        client.apiClient.request(
            endpoint: .missingEvents(since: lastSyncedAt, cids: .init(cids))
        ) { [weak self] in
            switch $0 {
            case let .success(payload):
                log.info("Did receive \(payload.eventPayloads.count) missing events: \(payload.eventPayloads)")
                
                // 1. Decode events
                let events: [Event] = payload.eventPayloads.compactMap {
                    do {
                        return try $0.event()
                    } catch {
                        log.error("Failed to decode event from payload: \($0)")
                        return nil
                    }
                }
                
                // 2. Save events to the database without publishing
                self?.client.eventNotificationCenter.feedEventsToMiddlewares(
                    events,
                    shouldPostEvents: false,
                    completion: {
                        // 3. Get most recent evetn timestamp
                        let mostRecentEventTimestamp = payload.eventPayloads.last?.createdAt ?? lastSyncedAt
                        
                        // 4. Report all given channels as synced and the new sync date
                        completion(.success((cids, mostRecentEventTimestamp)))
                    }
                )
            case let .failure(error):
                guard error.isTooManyMissingEventsToSyncError else {
                    log.error("Fail to get missing events: \(error)")
                    completion(.failure(error))
                    return
                }
                
                log.info(
                    """
                    Backend couldn't handle replaying missing events - there was too many (>1000)
                    events to replay. Cleaning local channels data and refetching it from scratch
                    """
                )
                
                // Report no channels as synced and current date
                completion(.success(([], Date())))
            }
        }
    }
        
    func syncChannelListQueries(
        syncedCIDs: Set<ChannelId>,
        completion: @escaping ([(ChannelListQuery, Error?)]) -> Void
    ) {
        let group = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 1)
        var results: [(ChannelListQuery, Error?)] = []

        for controller in activeChannelListControllers {
            group.enter()
            
            controller.recover(syncedCIDs: syncedCIDs) { error in
                semaphore.wait()
                results += [(controller.query, error)]
                semaphore.signal()
                
                group.leave()
            }
        }
        
        group.notify(queue: .global()) {
            completion(results)
        }
    }
        
    func syncActiveChannels(
        syncedCIDs: Set<ChannelId>,
        completion: @escaping ([(ChannelQuery, Error?)]) -> Void
    ) {
        let group = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 1)
        var results: [(ChannelQuery, Error?)] = []
        
        for controller in activeChannelControllers {
            group.enter()
            
            controller.recover(syncedCIDs: syncedCIDs) { error in
                semaphore.wait()
                results += [(controller.channelQuery, error)]
                semaphore.signal()
                
                group.leave()
            }
        }
        
        group.notify(queue: .global()) {
            completion(results)
        }
    }
    
    func bumpLastSyncDate(_ lastSyncedAt: Date, completion: @escaping () -> Void) {
        client.databaseContainer.write({ session in
            session.currentUser?.lastSyncedAt = lastSyncedAt
        }, completion: { _ in
            completion()
        })
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
    }
}

private extension Error {
    /// Backend responds with 400 if there was more than 1000 events to replay
    var isTooManyMissingEventsToSyncError: Bool {
        isBackendErrorWith400StatusCode
    }
}
