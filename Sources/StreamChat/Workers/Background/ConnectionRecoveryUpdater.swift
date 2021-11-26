//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// The type that descibes chat component that might need recovery when client reconnects.
protocol ChatRecoverableComponent: AnyObject {}

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
        client.clientUpdater.connect()
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
