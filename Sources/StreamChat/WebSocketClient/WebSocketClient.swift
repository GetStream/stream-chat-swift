//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

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
    @Atomic fileprivate(set) var connectionState: WebSocketConnectionState = .disconnected() {
        didSet {
            log.info("Web socket connection state changed: \(connectionState)")
            connectionStateDelegate?.webSocketClient(self, didUpdateConectionState: connectionState)
            
            if connectionState.isConnected {
                reconnectionStrategy.sucessfullyConnected()
            }
            
            pingController.connectionStateDidChange(connectionState)
            
            if case .disconnected = connectionState {
                // No reconnection attempts are scheduled
                cancelBackgroundTaskIfNeeded()
            }
            
            // Publish Connection event with the new state
            let event = ConnectionStatusUpdated(webSocketConnectionState: connectionState)
            eventNotificationCenter.process(event)
        }
    }
    
    weak var connectionStateDelegate: ConnectionStateDelegate?
    
    /// Web socket connection options
    var options: Options = [.staysConnectedInBackground]
    
    /// The endpoint used for creating a web socket connection.
    ///
    /// Changing this value doesn't automatically update the existing connection. You need to manually call `disconnect`
    /// and `connect` to make a new connection to the updated endpoint.
    var connectEndpoint: Endpoint<EmptyResponse>?
    
    /// The decoder used to decode incoming events
    private let eventDecoder: AnyEventDecoder
    
    /// The web socket engine used to make the actual WS connection
    private(set) var engine: WebSocketEngine?
    
    /// If in the `waitingForReconnect` state, this variable contains the reconnection timer.
    private var reconnectionTimer: TimerControl?
    
    /// The queue on which web socket engine methods are called
    private let engineQueue: DispatchQueue = .init(label: "io.getStream.chat.core.web_socket_engine_queue", qos: .userInitiated)
    
    private let requestEncoder: RequestEncoder
    
    /// The session config used for the web socket engine
    private let sessionConfiguration: URLSessionConfiguration
    
    /// An object describing reconnection behavior after the web socket is disconnected.
    private var reconnectionStrategy: WebSocketClientReconnectionStrategy
    
    /// Used for starting and ending background tasks. Typically, this is provided by `UIApplication` which conforms
    /// to `BackgroundTaskScheduler` automatically.
    private lazy var backgroundTaskScheduler: BackgroundTaskScheduler? = environment.backgroundTaskScheduler
    
    /// The identifier of the currently running background task. `nil` of no background task is running.
    private var activeBackgroundTask: UIBackgroundTaskIdentifier?
    
    /// The internet connection observer we use for recovering when the connection was offline for some time.
    private let internetConnection: InternetConnection
    
    /// An object containing external dependencies of `WebSocketClient`
    private let environment: Environment
    
    private(set) lazy var pingController: WebSocketPingController = {
        let pingController = environment.createPingController(environment.timerType, engineQueue)
        pingController.delegate = self
        return pingController
    }()
    
    private func createEngineIfNeeded(for connectEndpoint: Endpoint<EmptyResponse>) -> WebSocketEngine {
        let request: URLRequest
        do {
            request = try requestEncoder.encodeRequest(for: connectEndpoint)
        } catch {
            fatalError("Failed to create WebSocketEngine with error: \(error)")
        }

        if let existedEngine = engine, existedEngine.request == request {
            return existedEngine
        }

        let engine = environment.createEngine(request, sessionConfiguration, engineQueue)
        engine.delegate = self
        return engine
    }
    
    init(
        sessionConfiguration: URLSessionConfiguration,
        requestEncoder: RequestEncoder,
        eventDecoder: AnyEventDecoder,
        eventNotificationCenter: EventNotificationCenter,
        internetConnection: InternetConnection,
        reconnectionStrategy: WebSocketClientReconnectionStrategy = DefaultReconnectionStrategy(),
        environment: Environment = .init()
    ) {
        self.environment = environment
        self.requestEncoder = requestEncoder
        self.sessionConfiguration = sessionConfiguration
        self.reconnectionStrategy = reconnectionStrategy
        self.eventDecoder = eventDecoder
        self.internetConnection = internetConnection

        self.eventNotificationCenter = eventNotificationCenter
        self.eventNotificationCenter.add(middleware: HealthCheckMiddleware(webSocketClient: self))
        
        startListeningForAppStateUpdates()
    }
    
    /// Connects the web connect.
    ///
    /// Calling this method has no effect is the web socket is already connected, or is in the connecting phase.
    func connect() {
        guard let endpoint = connectEndpoint else {
            log.assertionFailure("Attempt to connect `web-socket` while endpoint is missing")
            return
        }

        switch connectionState {
        // Calling connect in the following states has no effect
        case .connecting, .waitingForConnectionId, .connected(connectionId: _):
            return
        default: break
        }
        
        engine = createEngineIfNeeded(for: endpoint)
        
        // Cancel the reconnection timer if exists
        reconnectionTimer?.cancel()
        
        connectionState = .connecting
        
        engineQueue.async { [engine] in
            engine!.connect()
        }
    }
    
    /// Disconnects the web socket.
    ///
    /// Calling this function has no effect, if the connection is in an inactive state.
    /// - Parameter source: Additional information about the source of the disconnection. Default value is `.userInitiated`.
    func disconnect(source: WebSocketConnectionState.DisconnectionSource = .userInitiated) {
        connectionState = .disconnecting(source: source)
        engineQueue.async { [engine] in
            engine?.disconnect()
        }
    }
    
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
        guard options.contains(.staysConnectedInBackground), connectionState.isActive else { return }
        
        let backgroundTask = backgroundTaskScheduler?.beginBackgroundTask { [weak self] in
            self?.disconnect(source: .systemInitiated)
            // We need to call `endBackgroundTask` else our app will be killed
            self?.cancelBackgroundTaskIfNeeded()
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
            backgroundTaskScheduler?.endBackgroundTask(backgroundTask)
            activeBackgroundTask = nil
        }
    }
}

protocol ConnectionStateDelegate: AnyObject {
    func webSocketClient(_ client: WebSocketClient, didUpdateConectionState state: WebSocketConnectionState)
}

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
        
        var backgroundTaskScheduler: BackgroundTaskScheduler? = {
            if Bundle.main.isAppExtension {
                /// No background task scheduler exists for app extensions.
                return nil
            } else {
                /// We can't use `UIApplication.shared` directly because there's no way to convince the compiler
                /// this code is accessible only for non-extension executables.
                return UIApplication.value(forKeyPath: "sharedApplication") as? UIApplication
            }
        }()
    }
}

// MARK: - Web Socket Delegate

extension WebSocketClient: WebSocketEngineDelegate {
    func webSocketDidConnect() {
        connectionState = .waitingForConnectionId
    }
    
    func webSocketDidReceiveMessage(_ message: String) {
        do {
            let messageData = Data(message.utf8)
            log.debug("Event received:\n\(messageData.debugPrettyPrintedJSON)")

            let event = try eventDecoder.decode(from: messageData)
            eventNotificationCenter.process(event)
        } catch is ClientError.UnsupportedEventType {
            log.info("Skipping unsupported event type with payload: \(message)")
            
        } catch {
            // Check if the message contains an error object from the server
            let webSocketError = message
                .data(using: .utf8)
                .flatMap { try? JSONDecoder.default.decode(WebSocketErrorContainer.self, from: $0) }
                .map { ClientError.WebSocket(with: $0?.error) }
            
            if let webSocketError = webSocketError {
                // If there is an error from the server, the connection is about to be disconnected
                connectionState = .disconnecting(source: .serverInitiated(error: webSocketError))
            }
        }
    }
    
    func webSocketDidDisconnect(error engineError: WebSocketEngineError?) {
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
            connectionState = .disconnected(error: disconnectionError.map { ClientError.WebSocket(with: $0) })

            // If the disconnection error was one of the internet-is-down error, schedule reconnecting once the
            // connection is back online.
            guard disconnectionError?.isInternetOfflineError == true else { return }
            
            internetConnection.notifyOnce(when: { $0.isAvailable }) { [weak self] in
                // Check the current state is still "disconnected" with an internet-down error. If not, it means
                // the state was changed manually and we don't want to reconnect automatically.
                if case let .disconnected(error) = self?.connectionState,
                   error?.underlyingError?.isInternetOfflineError == true {
                    self?.connect()
                }
            }
        }
    }
}

// MARK: - Ping Controller Delegate

extension WebSocketClient: WebSocketPingControllerDelegate {
    func sendPing() {
        engineQueue.async { [engine] in
            engine?.sendPing()
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

// MARK: - Test helpers

#if TESTS
extension WebSocketClient {
    /// Simulates connection status change
    func simulateConnectionStatus(_ status: WebSocketConnectionState) {
        connectionState = status
    }
}
#endif

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

    func handle(event: Event, session: DatabaseSession) -> Event? {
        guard let healthCheckEvent = event as? HealthCheckEvent else {
            // Do nothing and forward the event
            return event
        }
        
        if let webSocketClient = webSocketClient {
            webSocketClient.pingController.pongRecieved()
            if webSocketClient.connectionState.isConnected == false {
                webSocketClient.connectionState = .connected(connectionId: healthCheckEvent.connectionId)
            }
        }
        
        // Don't forward the event
        return nil
    }
}
