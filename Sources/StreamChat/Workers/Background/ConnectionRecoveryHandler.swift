//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// The type that keeps track of active chat components and asks them to reconnect when it's needed
protocol ConnectionRecoveryHandler: ConnectionStateDelegate {
    func start()
    func stop()
}

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
final class DefaultConnectionRecoveryHandler: ConnectionRecoveryHandler {
    // MARK: - Properties

    private let webSocketClient: WebSocketClient
    private let eventNotificationCenter: EventNotificationCenter
    private let syncRepository: SyncRepository
    private let backgroundTaskScheduler: BackgroundTaskScheduler?
    private let internetConnection: InternetConnection
    private let reconnectionTimerType: Timer.Type
    private var reconnectionStrategy: RetryStrategy
    private var reconnectionTimer: TimerControl?
    private let keepConnectionAliveInBackground: Bool

    // MARK: - Init

    init(
        webSocketClient: WebSocketClient,
        eventNotificationCenter: EventNotificationCenter,
        syncRepository: SyncRepository,
        backgroundTaskScheduler: BackgroundTaskScheduler?,
        internetConnection: InternetConnection,
        reconnectionStrategy: RetryStrategy,
        reconnectionTimerType: Timer.Type,
        keepConnectionAliveInBackground: Bool
    ) {
        self.webSocketClient = webSocketClient
        self.eventNotificationCenter = eventNotificationCenter
        self.syncRepository = syncRepository
        self.backgroundTaskScheduler = backgroundTaskScheduler
        self.internetConnection = internetConnection
        self.reconnectionStrategy = reconnectionStrategy
        self.reconnectionTimerType = reconnectionTimerType
        self.keepConnectionAliveInBackground = keepConnectionAliveInBackground
    }

    func start() {
        subscribeOnNotifications()
    }

    func stop() {
        unsubscribeFromNotifications()
        cancelReconnectionTimer()
    }

    deinit {
        stop()
    }
}

// MARK: - Subscriptions

private extension DefaultConnectionRecoveryHandler {
    func subscribeOnNotifications() {
        backgroundTaskScheduler?.startListeningForAppStateUpdates(
            onEnteringBackground: { [weak self] in self?.appDidEnterBackground() },
            onEnteringForeground: { [weak self] in self?.appDidBecomeActive() }
        )

        internetConnection.notificationCenter.addObserver(
            self,
            selector: #selector(internetConnectionAvailabilityDidChange(_:)),
            name: .internetConnectionAvailabilityDidChange,
            object: nil
        )
    }

    func unsubscribeFromNotifications() {
        backgroundTaskScheduler?.stopListeningForAppStateUpdates()

        internetConnection.notificationCenter.removeObserver(
            self,
            name: .internetConnectionStatusDidChange,
            object: nil
        )
    }
}

// MARK: - Event handlers

extension DefaultConnectionRecoveryHandler {
    private func appDidBecomeActive() {
        log.debug("App -> ✅", subsystems: .webSocket)

        backgroundTaskScheduler?.endTask()

        reconnectIfNeededFromOffline()
    }

    private func appDidEnterBackground() {
        log.debug("App -> 💤", subsystems: .webSocket)

        guard canBeDisconnected else {
            // Client is not trying to connect nor connected
            return
        }

        guard keepConnectionAliveInBackground else {
            // We immediately disconnect
            disconnectIfNeeded()
            return
        }

        guard let scheduler = backgroundTaskScheduler else { return }

        let succeed = scheduler.beginTask { [weak self] in
            log.debug("Background task -> ❌", subsystems: .webSocket)

            self?.disconnectIfNeeded()
        }

        if succeed {
            log.debug("Background task -> ✅", subsystems: .webSocket)
        } else {
            // Can't initiate a background task, close the connection
            disconnectIfNeeded()
        }
    }

    @objc private func internetConnectionAvailabilityDidChange(_ notification: Notification) {
        guard let isAvailable = notification.internetConnectionStatus?.isAvailable else {
            return
        }

        log.debug("Internet -> \(isAvailable ? "✅" : "❌")", subsystems: .webSocket)

        if isAvailable {
            reconnectIfNeededFromOffline()
        } else {
            disconnectIfNeeded()
        }
    }

    func webSocketClient(_ client: WebSocketClient, didUpdateConnectionState state: WebSocketConnectionState) {
        log.debug("Connection state: \(state)", subsystems: .webSocket)

        switch state {
        case .connecting:
            cancelReconnectionTimer()

        case .connected:
            reconnectionStrategy.resetConsecutiveFailures()
            syncRepository.syncLocalState {
                log.info("Local state sync completed", subsystems: .offlineSupport)
            }

        case .disconnected:
            scheduleReconnectionTimerIfNeeded()
        case .initialized, .waitingForConnectionId, .disconnecting:
            break
        }
    }

    var canReconnectFromOffline: Bool {
        guard backgroundTaskScheduler?.isAppActive ?? true else {
            log.debug("Reconnection is not possible (app 💤)", subsystems: .webSocket)
            return false
        }

        switch webSocketClient.connectionState {
        case .disconnected(let source) where source == .userInitiated:
            return false
        case .initialized, .connected:
            return false
        default:
            break
        }

        return true
    }
}

// MARK: - Disconnection

private extension DefaultConnectionRecoveryHandler {
    /// Asks the web socket client to disconnect when the system decides we should drop the connection
    /// (app went to background, internet became unavailable, background task expired, etc.).
    ///
    /// The work is dispatched onto `WebSocketClient.engineQueue` to serialize the check-and-act
    /// (`canBeDisconnected` read + `webSocketClient.disconnect(...)` call) against the engine's
    /// own state mutations. All `WebSocketEngineDelegate` callbacks — `webSocketDidConnect`,
    /// `webSocketDidReceiveMessage`, `webSocketDidDisconnect` — run on `engineQueue` and mutate
    /// `WebSocketClient.connectionState`. By piggy-backing on the same serial queue, our decision
    /// cannot interleave with theirs.
    ///
    /// Bug this prevents: this method is called from multiple queues (main thread for app lifecycle
    /// events, `io.getStream.chat.internet-monitor` for reachability changes). Previously the flow was:
    ///
    ///   1. `canBeDisconnected` reads `connectionState == .connected` on the internet-monitor queue → returns `true`.
    ///   2. Meanwhile on `engineQueue`, `webSocketDidDisconnect` fires (Wi-Fi just dropped) and sets state to
    ///      `.disconnected(.serverInitiated)`.
    ///   3. The internet-monitor queue resumes and unconditionally calls `disconnect(source: .systemInitiated)`,
    ///      which writes `.disconnecting(.systemInitiated)`, overwriting the legitimate `.disconnected`.
    ///   4. The engine has already closed the socket, so no further `webSocketDidDisconnect` fires to
    ///      transition `.disconnecting → .disconnected`. State stays stuck at `.disconnecting`.
    ///   5. When Wi-Fi returns, automatic reconnection is rejected because the state's
    ///      `isAutomaticReconnectionEnabled` only matches `.disconnected`. The client never recovers.
    ///
    /// With this dispatch, the two writers are serialized on the same queue, so either ordering
    /// ends at `.disconnected` — no stuck `.disconnecting` state.
    func disconnectIfNeeded() {
        webSocketClient.engineQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.canBeDisconnected else { return }

            self.webSocketClient.disconnect(source: .systemInitiated) {
                log.debug("Did disconnect automatically", subsystems: .webSocket)
            }
        }
    }

    /// Asks the web socket client to reconnect when conditions allow it (app foregrounding,
    /// internet returning). Mirrors `disconnectIfNeeded`: the check (`canReconnectFromOffline`)
    /// and the act (`webSocketClient.connect()`) are dispatched onto `engineQueue` so they cannot
    /// race with the engine's own state mutations.
    func reconnectIfNeededFromOffline() {
        webSocketClient.engineQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.canReconnectFromOffline else { return }

            self.webSocketClient.connect()
        }
    }

    var canBeDisconnected: Bool {
        let state = webSocketClient.connectionState

        switch state {
        case .connecting, .waitingForConnectionId, .connected:
            log.debug("Will disconnect automatically from \(state) state", subsystems: .webSocket)

            return true
        default:
            log.debug("Disconnect is not needed in \(state) state", subsystems: .webSocket)

            return false
        }
    }
}

// MARK: - Reconnection Timer

private extension DefaultConnectionRecoveryHandler {
    func scheduleReconnectionTimerIfNeeded() {
        guard canReconnectAutomatically else { return }

        scheduleReconnectionTimer()
    }

    func scheduleReconnectionTimer() {
        let delay = reconnectionStrategy.getDelayAfterTheFailure()

        log.debug("Timer ⏳ \(delay) sec", subsystems: .webSocket)

        reconnectionTimer = reconnectionTimerType.schedule(
            timeInterval: delay,
            queue: .main,
            onFire: { [weak self] in
                log.debug("Timer 🔥", subsystems: .webSocket)

                self?.webSocketClient.engineQueue.async { [weak self] in
                    guard let self = self else { return }
                    guard self.canReconnectAutomatically else { return }

                    self.webSocketClient.connect()
                }
            }
        )
    }

    func cancelReconnectionTimer() {
        guard reconnectionTimer != nil else { return }

        log.debug("Timer ❌", subsystems: .webSocket)

        reconnectionTimer?.cancel()
        reconnectionTimer = nil
    }

    var canReconnectAutomatically: Bool {
        guard webSocketClient.connectionState.isAutomaticReconnectionEnabled else {
            log.debug("Reconnection is not required (\(webSocketClient.connectionState))", subsystems: .webSocket)
            return false
        }

        guard backgroundTaskScheduler?.isAppActive ?? true else {
            log.debug("Reconnection is not possible (app 💤)", subsystems: .webSocket)
            return false
        }

        log.debug("Will reconnect automatically", subsystems: .webSocket)

        return true
    }
}
