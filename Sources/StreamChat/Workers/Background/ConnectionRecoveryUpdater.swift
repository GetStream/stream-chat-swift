//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// The type that descibes chat component that might need recovery when client reconnects.
protocol ChatRecoverableComponent: AnyObject {
    typealias LocalSyncedCIDs = Set<ChannelId>
    typealias LocalWatchedCIDs = Set<ChannelId>
    
    /// Says if the component needs recovery.
    var requiresRecovery: Bool { get }
    
    /// Recovers a component giving it information about already synced and watched channels.
    ///
    /// The completion should return set of channel IDs related to this component that were recovered and watched.
    func recover(
        syncedCIDs: LocalSyncedCIDs,
        watchedCIDs: LocalWatchedCIDs,
        completion: @escaping (Result<LocalWatchedCIDs, Error>) -> Void
    )
}

/// The type that keeps track of active chat components and asks them to reconnect when it's needed
protocol ConnectionRecoveryHandler: AnyObject {
    /// The array of registered channel list components.
    var registeredChannelLists: [ChatRecoverableComponent] { get }
    
    /// The array of registered channels components.
    var registeredChannels: [ChatRecoverableComponent] { get }

    /// Registers channel list component as one that might need recovery on reconnect.
    func register(channelList: ChatRecoverableComponent)
    
    /// Registers channel component as one that might need recovery on reconnect.
    func register(channel: ChatRecoverableComponent)
}

extension ConnectionRecoveryHandler {
    /// The array of registered channel list components that need recovery.
    var channelListsToRecover: [ChatRecoverableComponent] {
        registeredChannelLists.filter(\.requiresRecovery)
    }
    
    /// The array of registered channel components that need recovery.
    var channelsToRecover: [ChatRecoverableComponent] {
        registeredChannels.filter(\.requiresRecovery)
    }
}

final class ConnectionRecoveryUpdater {
    // MARK: - Properties
    
    private unowned var client: ChatClient
    private let eventNotificationCenter: EventNotificationCenter
    private let backgroundTaskScheduler: BackgroundTaskScheduler?
    private let internetConnection: InternetConnection
    private let componentsAccessQueue = DispatchQueue(label: "co.getStream.ConnectionRecoveryUpdater")
    private var channelLists: [Weak<ChatRecoverableComponent>] = []
    private var channels: [Weak<ChatRecoverableComponent>] = []

    // MARK: - Init
    
    init(
        client: ChatClient,
        environment: Environment = .init()
    ) {
        self.client = client
        backgroundTaskScheduler = environment.backgroundTaskSchedulerBuilder()
        internetConnection = environment.internetConnectionBuilder(client.eventNotificationCenter)
        eventNotificationCenter = client.eventNotificationCenter
        
        subscribeOnNotifications()
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    // MARK: - Subscriptions
        
    private func subscribeOnNotifications() {
        backgroundTaskScheduler?.startListeningForAppStateUpdates(
            onEnteringBackground: { [weak self] in self?.handleAppDidEnterBackground() },
            onEnteringForeground: { [weak self] in self?.handleAppDidBecomeActive() }
        )
        
        eventNotificationCenter.addObserver(
            self,
            selector: #selector(didChangeInternetConnectionStatus(_:)),
            name: .internetConnectionStatusDidChange,
            object: nil
        )
    }
    
    private func unsubscribeFromNotifications() {
        backgroundTaskScheduler?.stopListeningForAppStateUpdates()
        backgroundTaskScheduler?.endTask()
        
        eventNotificationCenter.removeObserver(
            self,
            name: .internetConnectionStatusDidChange,
            object: nil
        )
    }

    // MARK: - Notification handlers
        
    private func handleAppDidBecomeActive() {
        backgroundTaskScheduler?.endTask()
        
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
        
        guard let scheduler = backgroundTaskScheduler else { return }
        
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
        
        guard internetConnection.status.isAvailable else {
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
                    
                    // 4. Recover active channels
                    self?.recover(
                        channels: self?.channelsToRecover ?? [],
                        syncedCIDs: syncedCIDs
                    ) {
                        guard case let .success(watchedCIDs) = $0 else {
                            log.error("Failed to get missing events for channels: \($0.error?.localizedDescription ?? "")")
                            return
                        }
                        
                        // 5. Recover active channel lists
                        self?.recover(
                            channelLists: self?.channelListsToRecover ?? [],
                            syncedCIDs: syncedCIDs,
                            watchedCIDs: watchedCIDs
                        ) {
                            guard $0 == nil else {
                                log
                                    .error(
                                        "Failed to to sync one or more active channel list queries: \($0?.localizedDescription ?? "")"
                                    )
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
    
    private func loadSyncData(completion: @escaping (Result<(Set<ChannelId>, Date), Error>) -> Void) {
        client.databaseContainer.write { session in
            guard let currentUser = session.currentUser else {
                completion(.failure(ClientError.CurrentUserDoesNotExist()))
                return
            }
            
            let cids = Set(
                session
                    .loadAllChannelListQueries()
                    .flatMap(\.channels)
                    .compactMap { try? ChannelId(cid: $0.cid) }
            )
            
            completion(.success((cids, currentUser.lastSyncedAt)))
        }
    }
    
    private func fetchAndSaveMissingEvents(
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
                self?.eventNotificationCenter.processMissingEvents(payload.eventPayloads, post: false) {
                    // TODO: Check most recent events is first or last
                    let mostRecentEventTimestamp = payload.eventPayloads.first?.createdAt ?? lastSyncedAt
                    
                    completion(.success((cids, mostRecentEventTimestamp)))
                }
            case let .failure(error):
                guard error.isTooManyMissingEventsToSyncError else {
                    log.error("Fail to get missing events: \(error)")
                    completion(.failure(error))
                    return
                }
                
                log.info(
                    """
                    Backend couldn't handle replaying missing events - there was too many (>1000) events to replay. \
                    Cleaning local channels data and refetching it from scratch
                    Backend couldn't handle replaying missing events - there was too many (>1000)
                    events to replay. Cleaning local channels data and refetching it from scratch
                    """
                )
                
                completion(.success(([], Date())))
            }
        }
    }
    
    private func recover(
        channels: [ChatRecoverableComponent],
        syncedCIDs: ChatRecoverableComponent.LocalSyncedCIDs,
        completion: @escaping (Result<ChatRecoverableComponent.LocalWatchedCIDs, Error>) -> Void
    ) {
        let group = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 1)
        
        var watchedCIDs = ChatRecoverableComponent.LocalWatchedCIDs()
        var errors = [Error]()

        for channel in channels {
            group.enter()
            
            channel.recover(syncedCIDs: syncedCIDs, watchedCIDs: []) {
                semaphore.wait()
                switch $0 {
                case let .success(newWatchedCIDs):
                    watchedCIDs.formUnion(newWatchedCIDs)
                case let .failure(error):
                    errors.append(error)
                }
                semaphore.signal()
                
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if let error = errors.first {
                completion(.failure(error))
            } else {
                completion(.success(watchedCIDs))
            }
        }
    }
    
    private func recover(
        channelLists: [ChatRecoverableComponent],
        syncedCIDs: ChatRecoverableComponent.LocalSyncedCIDs,
        watchedCIDs: ChatRecoverableComponent.LocalWatchedCIDs,
        completion: @escaping (Error?) -> Void
    ) {
        guard let channelList = channelLists.first else {
            completion(nil)
            return
        }
        
        channelList.recover(syncedCIDs: syncedCIDs, watchedCIDs: watchedCIDs) { [weak self] in
            switch $0 {
            case let .success(newWatchedCIDs):
                self?.recover(
                    channelLists: .init(channelLists.dropFirst()),
                    syncedCIDs: syncedCIDs,
                    watchedCIDs: watchedCIDs.union(newWatchedCIDs),
                    completion: completion
                )
            case let .failure(error):
                completion(error)
            }
        }
    }
    
    private func bumpLastSyncDate(_ lastSyncedAt: Date, completion: @escaping () -> Void) {
        client.databaseContainer.write({ session in
            session.currentUser?.lastSyncedAt = lastSyncedAt
        }, completion: { _ in
            completion()
        })
    }
}

// MARK: - ConnectionRecoveryHandler

extension ConnectionRecoveryUpdater: ConnectionRecoveryHandler {
    var registeredChannelLists: [ChatRecoverableComponent] {
        channelLists.compactMap(\.value)
    }
    
    var registeredChannels: [ChatRecoverableComponent] {
        channels.compactMap(\.value)
    }
    
    func register(channelList: ChatRecoverableComponent) {
        componentsAccessQueue.sync {
            channelLists.removeAll(where: { $0.value == nil || $0.value === channelList })
            channelLists.append(.init(value: channelList))
        }
    }
    
    func register(channel: ChatRecoverableComponent) {
        componentsAccessQueue.sync {
            channels.removeAll(where: { $0.value == nil || $0.value === channel })
            channels.append(.init(value: channel))
        }
    }
}

extension ConnectionRecoveryUpdater {
    struct Environment {
        var internetConnectionBuilder: (NotificationCenter) -> InternetConnection = {
            InternetConnection(notificationCenter: $0)
        }
        
        var backgroundTaskSchedulerBuilder: () -> BackgroundTaskScheduler? = {
            if Bundle.main.isAppExtension {
                // No background task scheduler exists for app extensions.
                return nil
            } else {
                #if os(iOS)
                return IOSBackgroundTaskScheduler()
                #else
                // No need for background schedulers on macOS, app continues running when inactive.
                return nil
                #endif
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
    func processMissingEvents(_ payloads: [EventPayload], post: Bool = true, completion: (() -> Void)? = nil) {
        let events: [Event] = payloads.compactMap {
            do {
                return try $0.event()
            } catch {
                log.error("Failed to transform a payload into an event: \($0)")
                return nil
            }
        }
        
        process(
            events,
            post: post,
            completion: completion
        )
    }
}

private extension Error {
    /// Backend responds with 400 if there was more than 1000 events to replay
    var isTooManyMissingEventsToSyncError: Bool {
        isBackendErrorWith400StatusCode
    }
}

private extension WebSocketConnectionState {
    var shouldAutomaticallyReconnect: Bool {
        guard case let .disconnected(source) = self else { return false }
        
        switch source {
        case .systemInitiated, .noPongReceived:
            return true
        case .userInitiated, .serverInitiated:
            return false
        }
    }
}
