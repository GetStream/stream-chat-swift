//
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
                reconnectionStrategy.sucessfullyConnected()
                
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
    lazy var engine: WebSocketEngine = createEngine()
    
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
    
    private let requestEncoder: RequestEncoder
    
    /// The session config used for the web socket engine
    private let sessionConfiguration: URLSessionConfiguration
    
    /// An object describing reconnection behavior after the web socket is disconnected.
    private var reconnectionStrategy: WebSocketClientReconnectionStrategy
    
    /// Used for starting and ending background tasks. Typically, this is provided by `UIApplication` which conforms
    /// to `BackgroundTaskScheduler` automatically.
    private lazy var backgroundTaskScheduler: BackgroundTaskScheduler = environment.backgroundTaskScheduler
    
    /// The identifier of the currently running background task. `nil` of no background task is running.
    private var activeBackgroundTask: UIBackgroundTaskIdentifier?
    
    /// An object containing external dependencies of `WebSocketClient`
    private let environment: Environment
    
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
    
    init(connectEndpoint: Endpoint<EmptyResponse>,
         sessionConfiguration: URLSessionConfiguration,
         requestEncoder: RequestEncoder,
         eventDecoder: AnyEventDecoder,
         eventMiddlewares: [EventMiddleware],
         reconnectionStrategy: WebSocketClientReconnectionStrategy = DefaultReconnectionStrategy(),
         environment: Environment = .init()) {
        self.environment = environment
        self.connectEndpoint = connectEndpoint
        self.requestEncoder = requestEncoder
        self.sessionConfiguration = sessionConfiguration
        middlewares = eventMiddlewares
        self.reconnectionStrategy = reconnectionStrategy
        self.eventDecoder = eventDecoder
        
        startListeningForAppStateUpdates()
    }
    
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
        
        // Engine needs to be recreated if the connection endpoint has changed. For example, when a new user is
        // logged in, or when an auth token is refreshed.
        if engineNeedsToBeRecreated {
            engineNeedsToBeRecreated = false
            engine = createEngine()
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
        
        var createEngine: (_ request: URLRequest, _ sessionConfiguration: URLSessionConfiguration, _ callbackQueue: DispatchQueue)
            -> WebSocketEngine = {
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
            
            middlewares.process(event: event) { [weak self] event in
                guard let self = self, let event = event else { return }
                
                if let event = event as? HealthCheck {
                    if self.connectionState.isConnected == false {
                        self.connectionState = .connected(connectionId: event.connectionId)
                    }
                } else {
                    self.notificationCenter.post(Notification(newEventReceived: event, sender: self))
                }
            }
            
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
        
        if shouldReconnect, let reconnectionDelay = reconnectionStrategy.reconnectionDelay(forConnectionError: disconnectionError) {
            let clientError = disconnectionError.map { ClientError.WebSocket(with: $0) }
            connectionState = .waitingForReconnect(error: clientError)
            
            reconnectionTimer = environment.timer
                .schedule(timeInterval: reconnectionDelay, queue: engineQueue) { [weak self] in
                    self?.connect()
                }
            
        } else {
            connectionState = .notConnected(error: disconnectionError.map { ClientError.WebSocket(with: $0) })
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
