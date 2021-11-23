//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

class WebSocketClient {
    /// The notification center `WebSocketClient` uses to send notifications about incoming events.
    let eventNotificationCenter: EventNotificationCenter
    
    /// The current state the web socket connection.
    @Atomic private(set) var connectionState: WebSocketConnectionState = .initialized {
        didSet {
            log.info("Web socket connection state changed: \(connectionState)", subsystems: .webSocket)
            connectionStateDelegate?.webSocketClient(self, didUpdateConnectionState: connectionState)
            
            if connectionState.isConnected {
                reconnectionStrategy.successfullyConnected()
            }
            
            pingController.connectionStateDidChange(connectionState)

            let previousStatus = ConnectionStatus(webSocketConnectionState: oldValue)
            let event = ConnectionStatusUpdated(webSocketConnectionState: connectionState)

            if event.connectionStatus != previousStatus {
                // Publish Connection event with the new state
                eventNotificationCenter.process(event)
            }
        }
    }
    
    weak var connectionStateDelegate: ConnectionStateDelegate?
    
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
    }
    
    /// Connects the web connect.
    ///
    /// Calling this method has no effect is the web socket is already connected, or is in the connecting phase.
    func connect() {
        guard let endpoint = connectEndpoint else {
            log.assertionFailure("Attempt to connect `web-socket` while endpoint is missing", subsystems: .webSocket)
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
}

protocol ConnectionStateDelegate: AnyObject {
    func webSocketClient(_ client: WebSocketClient, didUpdateConnectionState state: WebSocketConnectionState)
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
            log.debug("Event received:\n\(messageData.debugPrettyPrintedJSON)", subsystems: .webSocket)

            let event = try eventDecoder.decode(from: messageData)
            if let healthCheckEvent = event as? HealthCheckEvent {
                eventNotificationCenter.process(healthCheckEvent) { [weak self] connectionId in
                    self?.pingController.pongRecieved()
                    self?.connectionState = .connected(connectionId: connectionId)
                }
            } else {
                eventNotificationCenter.process(event)
            }
        } catch is ClientError.UnsupportedEventType {
            log.info("Skipping unsupported event type with payload: \(message)", subsystems: .webSocket)
            
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
        // or system initated disconnect (app enters background)
        let shouldReconnect = connectionState != .disconnecting(source: .userInitiated)
            && connectionState != .disconnecting(source: .systemInitiated)
        
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
