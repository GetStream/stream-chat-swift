//
// WebSocketClient.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

class WebSocketClient {
    /// The time interval to ping connection to keep it alive.
    static let pingTimeInterval: TimeInterval = 25
    
    /// Additional options for configuring web socket behavior.
    struct Options: OptionSet {
        let rawValue: Int
        /// When the app enters background, `WebSocketClient` starts a long term background task and stays connected.
        static let staysConnectedInBackground = Options(rawValue: 1 << 0)
    }
    
    /// The notification center `WebSocketClient` uses to send notifications about incoming events.
    private(set) lazy var notificationCenter: NotificationCenter = environment.notificationCenterBuilder()
    
    /// The current state the web socket connection.
    @Atomic private(set) var connectionState: ConnectionState = .notConnected() {
        didSet {
            log.info("Web socket connection state changed: \(connectionState)")
            connectionStateDelegate?.webSocketClient(self, didUpdateConectionState: connectionState)
            
            if connectionState.isConnected {
                pingTimer.resume()
            } else {
                pingTimer.suspend()
            }
            
            if case .notConnected = connectionState {
                // No reconnection attempts are scheduled
                cancelBackgroundTaskIfNeeded()
            }
        }
    }
    
    weak var connectionStateDelegate: ConnectionStateDelegate?
    
    /// Web socket connection options
    var options: Options = [.staysConnectedInBackground]
    
    /// Event middlewares used to pre-process incoming events before they are published
    var middlewares: [EventMiddleware]
    
    /// The decoder used to decode incoming events
    private let eventDecoder: AnyEventDecoder
    
    /// The web socket engine used to make the actual WS connection
    private lazy var engine: WebSocketEngine = {
        let engine = self.environment.engineBuilder(self.urlRequest, self.engineQueue)
        engine.delegate = self
        return engine
    }()
    
    /// The timer used for scheduling `ping` calls
    private lazy var pingTimer = environment.timer
        .scheduleRepeating(timeInterval: WebSocketClient.pingTimeInterval,
                           queue: engine.callbackQueue) { [weak self] in
            self?.engine.sendPing()
        }
    
    /// If in the `waitingForReconnect` state, this variable contains the reconnection timer.
    private var reconnectionTimer: TimerControl?
    
    /// The queue on which web socket engine methods are called
    private let engineQueue: DispatchQueue = .init(label: "io.getStream.chat.core.web_socket_engine_queue", qos: .default)
    
    /// The request used to establish web socket connection
    private let urlRequest: URLRequest
    
    /// An object describing reconnection behavior after the web socket is disconnected.
    private var reconnectionStrategy: WebSocketClientReconnectionStrategy
    
    /// Used for starting and ending background tasks. Typically, this is provided by `UIApplication` which conforms
    /// to `BackgroundTaskScheduler` automatically.
    private lazy var backgroundTaskScheduler: BackgroundTaskScheduler = environment.backgroundTaskScheduler
    
    /// The identifier of the currently running background task. `nil` of no background task is running.
    private var activeBackgroundTask: UIBackgroundTaskIdentifier?
    
    /// An object containing external dependencies of `WebSocketClient`
    private let environment: Environment
    
    init(
        urlRequest: URLRequest,
        eventDecoder: AnyEventDecoder,
        eventMiddlewares: [EventMiddleware],
        reconnectionStrategy: WebSocketClientReconnectionStrategy = DefaultReconnectionStrategy(),
        environment: Environment = .init()
    ) {
        self.environment = environment
        self.urlRequest = urlRequest
        middlewares = eventMiddlewares
        self.reconnectionStrategy = reconnectionStrategy
        self.eventDecoder = eventDecoder
        
        startListeningForAppStateUpdates()
    }
    
    private func startListeningForAppStateUpdates() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc
    private func handleAppDidEnterBackground() {
        guard options.contains(.staysConnectedInBackground), connectionState.isActive else { return }
        
        let backgroundTask = backgroundTaskScheduler.beginBackgroundTask { [weak self] in
            self?.disconnect(source: .systemInitiated)
        }
        
        if backgroundTask != .invalid {
            activeBackgroundTask = backgroundTask
        } else {
            // Can't initiate a background task, close the connection
            disconnect(source: .systemInitiated)
        }
    }
    
    @objc
    private func handleAppDidBecomeActive() {
        cancelBackgroundTaskIfNeeded()
    }
    
    private func cancelBackgroundTaskIfNeeded() {
        if let backgroundTask = activeBackgroundTask {
            backgroundTaskScheduler.endBackgroundTask(backgroundTask)
            activeBackgroundTask = nil
        }
    }
}

protocol ConnectionStateDelegate: AnyObject {
    func webSocketClient(_ client: WebSocketClient, didUpdateConectionState state: ConnectionState)
}

extension WebSocketClient {
    /// An object encapsulating all dependencies of `WebSocketClient`.
    struct Environment {
        var timer: Timer.Type = DefaultTimer.self
        
        var notificationCenterBuilder: () -> NotificationCenter = NotificationCenter.init
        
        var engineBuilder: (_ request: URLRequest, _ callbackQueue: DispatchQueue) -> WebSocketEngine = {
            if #available(iOS 13, *) {
                return URLSessionWebSocketEngine(request: $0, callbackQueue: $1)
            } else {
                return StarscreamWebSocketProvider(request: $0, callbackQueue: $1)
            }
        }
        
        var backgroundTaskScheduler: BackgroundTaskScheduler = UIApplication.shared
    }
}

extension WebSocketClient {
    /// Connects the web connect.
    ///
    /// Calling this method has no effect is the web socket is already connected, or is in the connecting phase.
    func connect() {
        switch connectionState {
        // Calling connect in the following states has no effect
        case .connecting, .waitingForConnectionId, .connected(connectionId: _):
            return
        default: break
        }
        
        // Cancel the reconnection timer if exists
        reconnectionTimer?.cancel()
        
        connectionState = .connecting
        
        engineQueue.async {
            self.engine.connect()
        }
    }
    
    /// Disconnects the web socket.
    ///
    /// Calling this function has no effect, if the connection is in an inactive state.
    /// - Parameter source: Additional information about the source of the disconnection. Default value is `.userInitiated`.
    func disconnect(source: ConnectionState.DisconnectionSource = .userInitiated) {
        connectionState = .disconnecting(source: source)
        engineQueue.async {
            self.engine.disconnect()
        }
    }
}

// MARK: - Web Socket Delegate

extension WebSocketClient: WebSocketEngineDelegate {
    func websocketDidConnect() {
        connectionState = .waitingForConnectionId
    }
    
    func websocketDidReceiveMessage(_ message: String) {
        do {
            let messageData = Data(message.utf8)
            let event = try eventDecoder.decode(data: messageData)
            
            if let event = event as? HealthCheck {
                if connectionState.isConnected == false {
                    connectionState = .connected(connectionId: event.connectionId)
                    reconnectionStrategy.sucessfullyConnected()
                }
            }
            
            middlewares.process(event: event) { [weak self] event in
                guard let self = self, let event = event else { return }
                self.notificationCenter.post(Notification(newEventReceived: event, sender: self))
            }
            
        } catch {
            // Check if the message contains an error object from the server
            let webSocketError = message
                .data(using: .utf8)
                .map { try? JSONDecoder.default.decode(WebSocketErrorContainer.self, from: $0) }
                .map { ClientError.WebSocketError(with: $0?.error) }
            
            if let webSocketError = webSocketError {
                // If there is an error from the server, the connection is about to be disconnected
                connectionState = .disconnecting(source: .serverInitiated(error: webSocketError))
            }
        }
    }
    
    func websocketDidDisconnect(error engineError: WebSocketEngineError?) {
        // Reconnection shouldn't happen for manually initiated disconnect
        let shouldReconnect = connectionState != .disconnecting(source: .userInitiated)
        
        let disconnectionError: Error?
        if case let .disconnecting(.serverInitiated(webSocketError)) = connectionState {
            disconnectionError = webSocketError?.underlyingError
        } else {
            disconnectionError = engineError
        }
        
        if shouldReconnect, let reconnectionDelay = reconnectionStrategy.reconnectionDelay(forConnectionError: disconnectionError) {
            let clientError = disconnectionError.map { ClientError.WebSocketError(with: $0) }
            connectionState = .waitingForReconnect(error: clientError)
            
            reconnectionTimer = environment.timer
                .schedule(timeInterval: reconnectionDelay, queue: engineQueue) { [weak self] in
                    self?.connect()
                }
            
        } else {
            connectionState = .notConnected(error: disconnectionError.map { ClientError.WebSocketError(with: $0) })
        }
    }
}

extension Notification.Name {
    /// The name of the notification posted when a new event is published/
    static let NewEventReceived = Notification.Name("io.getStream.chat.core.new_event_received")
}

extension Notification {
    private static let eventKey = "io.getStream.chat.core.event_key"
    
    init(newEventReceived event: Event, sender: Any) {
        self.init(name: .NewEventReceived, object: sender, userInfo: [Self.eventKey: event])
    }
    
    var event: Event? {
        userInfo?[Self.eventKey] as? Event
    }
}

extension ClientError {
    public class WebSocketError: ClientError {}
}

/// WebSocket Error
struct WebSocketErrorContainer: Decodable {
    /// A server error was received.
    let error: ErrorPayload
}

/// Used for starting and ending background tasks. `UIApplication` which conforms to `BackgroundTaskScheduler` automatically.
protocol BackgroundTaskScheduler {
    func beginBackgroundTask(expirationHandler: (() -> Void)?) -> UIBackgroundTaskIdentifier
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

extension UIApplication: BackgroundTaskScheduler {}
