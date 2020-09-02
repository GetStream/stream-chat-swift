//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

class WebSocketClient {
    /// Additional options for configuring web socket behavior.
    struct Options: OptionSet {
        let rawValue: Int
        /// When the app enters background, `WebSocketClient` starts a long term background task and stays connected.
        static let staysConnectedInBackground = Options(rawValue: 1 << 0)
    }
    
    /// The notification center `WebSocketClient` uses to send notifications about incoming events.
    let eventNotificationCenter: EventNotificationCenter
    
    /// The current state the web socket connection.
    @Atomic fileprivate(set) var connectionState: ConnectionState = .notConnected() {
        didSet {
            log.info("Web socket connection state changed: \(connectionState)")
            connectionStateDelegate?.webSocketClient(self, didUpdateConectionState: connectionState)
            
            if connectionState.isConnected {
                reconnectionStrategy.sucessfullyConnected()
            }
            
            pingController.connectionStateDidChange(connectionState)
            
            if case .notConnected = connectionState {
                // No reconnection attempts are scheduled
                cancelBackgroundTaskIfNeeded()
            }
        }
    }
    
    weak var connectionStateDelegate: ConnectionStateDelegate?
    
    /// Web socket connection options
    var options: Options = [.staysConnectedInBackground]
    
    /// The endpoint used for creating a web socket connection.
    ///
    /// Changing this value doesn't automatically update the existing connection. You need to manually call `disconnect`
    /// and `connect` to make a new connection to the updated endpoint.
    var connectEndpoint: Endpoint<EmptyResponse> {
        didSet {
            engineNeedsToBeRecreated = true
        }
    }
    
    /// The decoder used to decode incoming events
    private let eventDecoder: AnyEventDecoder
    
    /// The web socket engine used to make the actual WS connection
    private(set) lazy var engine: WebSocketEngine = createEngine()
    
    /// If in the `waitingForReconnect` state, this variable contains the reconnection timer.
    private var reconnectionTimer: TimerControl?
    
    /// The queue on which web socket engine methods are called
    private let engineQueue: DispatchQueue = .init(label: "io.getStream.chat.core.web_socket_engine_queue", qos: .userInitiated)
    
    private let requestEncoder: RequestEncoder
    
    /// The session config used for the web socket engine
    private let sessionConfiguration: URLSessionConfiguration
    
    /// The Internet Connection for notifications.
    private let internetConnection: InternetConnection
    private var internetConnectionNotificationToken: NSObjectProtocol?
    
    /// An object describing reconnection behavior after the web socket is disconnected.
    private var reconnectionStrategy: WebSocketClientReconnectionStrategy
    
    /// Used for starting and ending background tasks. Typically, this is provided by `UIApplication` which conforms
    /// to `BackgroundTaskScheduler` automatically.
    private lazy var backgroundTaskScheduler: BackgroundTaskScheduler = environment.backgroundTaskScheduler
    
    /// The identifier of the currently running background task. `nil` of no background task is running.
    private var activeBackgroundTask: UIBackgroundTaskIdentifier?
    
    /// An object containing external dependencies of `WebSocketClient`
    private let environment: Environment
    
    private(set) lazy var pingController: WebSocketPingController = {
        let pingController = environment.createPingController(environment.timerType, engineQueue)
        pingController.delegate = self
        return pingController
    }()
    
    private func createEngine() -> WebSocketEngine {
        do {
            let request = try requestEncoder.encodeRequest(for: connectEndpoint)
            let engine = environment.createEngine(request, sessionConfiguration, engineQueue)
            engine.delegate = self
            return engine
            
        } catch {
            fatalError("Failed to create WebSocketEngine with error: \(error)")
        }
    }
    
    @Atomic private var engineNeedsToBeRecreated = false
    
    init(
        connectEndpoint: Endpoint<EmptyResponse>,
        sessionConfiguration: URLSessionConfiguration,
        requestEncoder: RequestEncoder,
        eventDecoder: AnyEventDecoder,
        eventNotificationCenter: EventNotificationCenter,
        internetConnection: InternetConnection,
        reconnectionStrategy: WebSocketClientReconnectionStrategy,
        environment: Environment = .init()
    ) {
        self.environment = environment
        self.connectEndpoint = connectEndpoint
        self.requestEncoder = requestEncoder
        self.sessionConfiguration = sessionConfiguration
        self.internetConnection = internetConnection
        self.reconnectionStrategy = reconnectionStrategy
        self.eventDecoder = eventDecoder
        self.eventNotificationCenter = eventNotificationCenter
        self.eventNotificationCenter.add(middleware: HealthCheckMiddleware(webSocketClient: self))
        
        startListeningForAppStateUpdates()
        startListeningForInternetConnectionStatusUpdates()
    }
    
    deinit {
        // Unsubscribe from App State updates notifications.
        NotificationCenter.default.removeObserver(self)
        
        // Unsubscribe from Internet connection updates notifications.
        if let notificationToken = internetConnectionNotificationToken {
            NotificationCenter.default.removeObserver(notificationToken)
        }
    }
    
    /// Connects the web connect.
    ///
    /// Calling this method has no effect is the web socket is already connected, or is in the connecting phase.
    func connect() {
        switch connectionState {
        // Calling connect in the following states has no effect
        case .connecting, .waitingForConnectionId, .connected(connectionId: _): return
        default: break
        }
        
        // Engine needs to be recreated if the connection endpoint has changed. For example, when a new user is
        // logged in, or when an auth token is refreshed.
        if engineNeedsToBeRecreated {
            engineNeedsToBeRecreated = false
            engine = createEngine()
        }
        
        // Cancel the reconnection timer if exists
        reconnectionTimer?.cancel()
        
        connectionState = .connecting
        
        engineQueue.async { [engine] in
            engine.connect()
        }
    }
    
    /// Disconnects the web socket.
    ///
    /// Calling this function has no effect, if the connection is in an inactive state.
    /// - Parameter source: Additional information about the source of the disconnection. Default value is `.userInitiated`.
    func disconnect(source: ConnectionState.DisconnectionSource = .userInitiated) {
        guard connectionState.isActive else { return }
        
        connectionState = .disconnecting(source: source)
        engineQueue.async { [engine] in
            engine.disconnect()
        }
    }
    
    // MARK: App State
    
    private func startListeningForAppStateUpdates() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleAppDidEnterBackground() {
        guard options.contains(.staysConnectedInBackground), connectionState.isActive else {
            if connectionState.isActive {
                disconnect(source: .systemInitiated)
            }
            
            return
        }
        
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
    
    @objc private func handleAppDidBecomeActive() {
        cancelBackgroundTaskIfNeeded()
    }
    
    private func cancelBackgroundTaskIfNeeded() {
        if let backgroundTask = activeBackgroundTask {
            backgroundTaskScheduler.endBackgroundTask(backgroundTask)
            activeBackgroundTask = nil
        }
    }
    
    // MARK: Internet Connection
    
    private func startListeningForInternetConnectionStatusUpdates() {
        internetConnectionNotificationToken = NotificationCenter.default.addObserver(
            forName: .internetConnectionStatusDidChange,
            object: internetConnection,
            queue: .main, // we should handle it on the main thread, because it uses `UIApplication.shared.appState`,
            using: { [weak self] in self?.handleInternetConnectionStatus($0) }
        )
    }
    
    private func handleInternetConnectionStatus(_ notification: Notification) {
        guard let status = notification.internetConnectionStatus else { return }
        
        let appState = UIApplication.shared.applicationState
        
        switch status {
        case .available:
            if case .background = appState {
                return
            }
            
            if !connectionState.isConnected {
                connect()
            }
            
        case .unknown, .unavailable:
            cancelBackgroundTaskIfNeeded()
            
            if connectionState.isActive {
                disconnect(source: .internetConnectionUnavailable)
            }
        }
    }
}

// MARK: Connection State Delegate

protocol ConnectionStateDelegate: AnyObject {
    func webSocketClient(_ client: WebSocketClient, didUpdateConectionState state: ConnectionState)
}

// MARK: - Environment

extension WebSocketClient {
    /// An object encapsulating all dependencies of `WebSocketClient`.
    struct Environment {
        typealias CreatePingController = (_ timerType: Timer.Type, _ timerQueue: DispatchQueue) -> WebSocketPingController
        
        typealias CreateEngine = (
            _ request: URLRequest,
            _ sessionConfiguration: URLSessionConfiguration,
            _ callbackQueue: DispatchQueue
        ) -> WebSocketEngine
        
        var timerType: Timer.Type = DefaultTimer.self
        
        var createPingController: CreatePingController = WebSocketPingController.init
        
        var createEngine: CreateEngine = {
            if #available(iOS 13, *) {
                return URLSessionWebSocketEngine(request: $0, sessionConfiguration: $1, callbackQueue: $2)
            } else {
                return StarscreamWebSocketProvider(request: $0, sessionConfiguration: $1, callbackQueue: $2)
            }
        }
        
        var backgroundTaskScheduler: BackgroundTaskScheduler = UIApplication.shared
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
            let event = try eventDecoder.decode(from: messageData)
            eventNotificationCenter.process(event)
        } catch is ClientError.UnsupportedEventType {
            log.info("Skipping unsupported event type with payload: \(message)")
            
        } catch {
            // Check if the message contains an error object from the server
            let webSocketError = message
                .data(using: .utf8)
                .map { try? JSONDecoder.default.decode(WebSocketErrorContainer.self, from: $0) }
                .map { ClientError.WebSocket(with: $0?.error) }
            
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
        
        if shouldReconnect,
            let reconnectionDelay = reconnectionStrategy.reconnectionDelay(forConnectionError: disconnectionError) {
            let clientError = disconnectionError.map { ClientError.WebSocket(with: $0) }
            connectionState = .waitingForReconnect(error: clientError)
            
            reconnectionTimer = environment.timerType
                .schedule(timeInterval: reconnectionDelay, queue: engineQueue) { [weak self] in self?.connect() }
            
        } else {
            connectionState = .notConnected(error: disconnectionError.map { ClientError.WebSocket(with: $0) })
        }
    }
}

// MARK: - Ping Controller Delegate

extension WebSocketClient: WebSocketPingControllerDelegate {
    func sendPing() {
        engineQueue.async { [engine] in
            engine.sendPing()
        }
    }
    
    func disconnectOnNoPongReceived() {
        disconnect(source: .noPongReceived)
    }
}

// MARK: - Notifications

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
    public class WebSocket: ClientError {}
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

struct HealthCheckMiddleware: EventMiddleware {
    private(set) weak var webSocketClient: WebSocketClient?

    func handle(event: Event, completion: @escaping (Event?) -> Void) {
        guard let healthCheckEvent = event as? HealthCheckEvent else {
            // Do nothing and forward the event
            completion(event)
            return
        }
        
        if let webSocketClient = webSocketClient {
            webSocketClient.pingController.pongRecieved()
            if webSocketClient.connectionState.isConnected == false {
                webSocketClient.connectionState = .connected(connectionId: healthCheckEvent.connectionId)
            }
        }
        
        // Don't forward the event
        completion(nil)
    }
}
