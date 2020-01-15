//
//  WebSocket.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 18/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import Starscream
import Reachability

/// A WebSocket connection callback type.
public typealias OnConnect = (WebSocket.Connection) -> Void
/// A WebSocket events callback type.
public typealias OnEvent = (WebSocket.Event) -> Void

/// A web socket client.
public final class WebSocket {
    private static let maxBackgroundTime: TimeInterval = 300
    static var pingTimeInterval = 30

    /// A WebSocket connection callback.
    public var onConnect: OnConnect? = { _ in }
    /// A WebSocket events callback.
    public var onEvent: OnEvent?
    
    private let webSocket: Starscream.WebSocket
    private let stayConnectedInBackground: Bool
    private let logger: ClientLogger?
    
    private var webSocketEvent = WebSocket.Event.disconnected(nil) {
        didSet {
            onEvent?(webSocketEvent)
            
            if let onConnect = onConnect,
                let connection = parseConnection(appState: UIApplication.shared.applicationState,
                                                 isInternetAvailable: InternetConnection.shared.isAvailable,
                                                 event: webSocketEvent) {
                onConnect(connection)
            }
        }
    }
    
    private(set) var lastJSONError: ClientErrorResponse?
    private(set) var lastConnectionId: String?
    private var consecutiveFailures: TimeInterval = 0
    private var isReconnecting = false
    private var goingToDisconnect: DispatchWorkItem?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var lastMessageHashValue: Int = 0
    private var lastMessageResponse: Response?
    private let webSocketInitiated: Bool
    
    private lazy var handshakeTimer = RepeatingTimer(timeInterval: .seconds(WebSocket.pingTimeInterval),
                                                     queue: webSocket.callbackQueue) { [weak self] in
                                                        self?.logger?.log("🏓", level: .info)
                                                        self?.webSocket.write(ping: Data())
    }
    
    /// Check if the web socket is connected and `connectionId` is not nil.
    public var isConnected: Bool {
        return lastConnectionId != nil && webSocket.isConnected
    }
    
    init(_ urlRequest: URLRequest, stayConnectedInBackground: Bool = true, logger: ClientLogger? = nil) {
        self.stayConnectedInBackground = stayConnectedInBackground
        self.logger = logger
        webSocket = Starscream.WebSocket(request: urlRequest)
        webSocket.callbackQueue = DispatchQueue(label: "io.getstream.Chat.WebSocket", qos: .userInitiated)
        webSocketInitiated = true
        webSocket.delegate = self
    }
    
    init() {
        webSocket = .init(url: BaseURL.placeholderURL)
        webSocketInitiated = false
        stayConnectedInBackground    = false
        logger = nil
    }
    
    deinit {
        if isConnected {
            logger?.log("💔 Disconnect on deinit")
            disconnect()
        }
    }
}

// MARK: - Connection

extension WebSocket {
    
    /// Connect to websocket.
    ///
    /// It's important to parse the connection to finish it. Call `parseConnection` when the connection was established.
    /// It will happen automatically if you will set `onConnect` callback to observe
    /// the connection status.
    /// - Skip if the Internet is not available.
    /// - Skip if it's already connected.
    /// - Skip if it's reconnecting.
    public func connect() {
        guard InternetConnection.shared.isAvailable else {
            disconnectedNoInternet()
            return
        }
        
        guard webSocketInitiated else {
            return
        }
        
        if webSocket.isConnected || isReconnecting {
            logger?.log("Skip connecting: isConnected = \(webSocket.isConnected), isReconnecting = \(isReconnecting)")
           return
        }
        
        logger?.log("❤️ Connecting...")
        logger?.log(webSocket.request)
        DispatchQueue.main.async(execute: webSocket.connect)
    }
    
    private func reconnect() {
        guard !isReconnecting else {
            return
        }
        
        let delay = delayForReconnect
        logger?.log("⏳ Reconnect in \(delay) sec")
        isReconnecting = true
        
        webSocket.callbackQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.isReconnecting = false
            self?.connect()
        }
    }
    
    private func disconnectInBackground() {
        guard stayConnectedInBackground else {
            disconnect()
            return
        }
        
        guard backgroundTask == .invalid else {
            return
        }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.disconnect()
        }
        
        if backgroundTask != .invalid {
            let goingToDisconnect: DispatchWorkItem = DispatchWorkItem { [weak self] in
                self?.disconnect()
            }
            
            webSocket.callbackQueue.asyncAfter(deadline: .now() + WebSocket.maxBackgroundTime, execute: goingToDisconnect)
            self.goingToDisconnect = goingToDisconnect
            
            if Client.shared.logOptions.isEnabled {
                ClientLogger.log("💜", "Background mode on")
            }
        } else {
            disconnect()
        }
    }
    
    private func cancelBackgroundWork() {
        goingToDisconnect?.cancel()
        goingToDisconnect = nil
        
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
            
            if Client.shared.logOptions.isEnabled {
                ClientLogger.log("💜", "Background mode off")
            }
        }
    }
    
    func disconnect() {
        logger?.log("Disconnecting...")
        
        guard webSocketInitiated else {
            logger?.log("Skip disconnecting: WebSocket was not initiated")
            return
        }
        
        if webSocket.isConnected {
            webSocket.disconnect()
            logger?.log("💔 Disconnected deliberately")
        } else {
            logger?.log("Skip disconnecting: WebSocket was not connected")
        }
        
        clearStateAfterDisconnect()
    }
    
    private func isTokenExpired() -> Bool {
        guard let lastJSONError = lastJSONError else {
            return false
        }
        
        let isTokenExpired = lastJSONError.code == ClientErrorResponse.tokenExpiredErrorCode
        return isTokenExpired && Client.shared.touchTokenProvider()
    }
    
    private func disconnectedNoInternet() {
        logger?.log("💔🕸 Disconnected: No Internet")
        clearStateAfterDisconnect()
        consecutiveFailures = 0
    }
    
    private func disconnected(_ error: Error? = nil) -> Connection {
        logger?.log("💔🤔 Disconnected")
        clearStateAfterDisconnect()
        
        if let error = error {
            var errorMessage = "🦄💔😡 Disconnected by error"
            
            if let lastJSONError = lastJSONError {
                errorMessage += ": \(lastJSONError)"
            }
            
            logger?.log(error, message: errorMessage)
            ClientLogger.showConnectionAlert(error, jsonError: lastJSONError)
            
            if !reconnectIfPossible(with: error) {
                consecutiveFailures = 0
                
                if let lastJSONError = lastJSONError, isStopError(error) {
                    return .disconnected(lastJSONError)
                }
            }
        } else {
            consecutiveFailures = 0
        }
        
        return .notConnected
    }
    
    private func reconnectIfPossible(with error: Swift.Error) -> Bool {
        if isStopError(error) {
            return false
        }
        
        if InternetConnection.shared.isAvailable {
            reconnect()
            return true
        }
        
        return false
    }
    
    private func isStopError(_ error: Swift.Error) -> Bool {
        if let lastJSONError = lastJSONError, lastJSONError.code == 1000 {
            return true
        }
        
        if let wsError = error as? WSError, wsError.code == 1000 {
            return true
        }
        
        return false
    }
    
    private func clearStateAfterDisconnect() {
        handshakeTimer.suspend()
        lastConnectionId = nil
        onEvent = nil
        cancelBackgroundWork()
    }
    
    private var delayForReconnect: TimeInterval {
        let maxDelay: TimeInterval = min(500 + consecutiveFailures * 2000, 25000) / 1000
        let minDelay: TimeInterval = min(max(250, (consecutiveFailures - 1) * 2000), 25000) / 1000
        consecutiveFailures += 1
        
        return minDelay + TimeInterval.random(in: 0...(maxDelay - minDelay))
    }
}

// MARK: - Web Socket Delegate

extension WebSocket: WebSocketDelegate {
    
    public func websocketDidConnect(socket: Starscream.WebSocketClient) {
        webSocketEvent = .connected
    }
    
    public func websocketDidDisconnect(socket: Starscream.WebSocketClient, error: Error?) {
        webSocketEvent = .disconnected(error)
    }
    
    public func websocketDidReceiveMessage(socket: Starscream.WebSocketClient, text: String) {
        if let webSocketResponse = parseMessage(text) {
            if case let .healthCheck(_, user) = webSocketResponse.event, user == nil {
                webSocketEvent = .pong
            } else {
                webSocketEvent = .message(webSocketResponse)
            }
        }
    }
    
    public func websocketDidReceiveData(socket: Starscream.WebSocketClient, data: Data) {}
    
    // MARK: Parsing
    
    public func parseConnection(appState: UIApplication.State, isInternetAvailable: Bool, event: WebSocket.Event) -> Connection? {
        guard webSocketInitiated else {
            return .notConnected
        }
        
        guard isInternetAvailable else {
            disconnectedNoInternet()
            return .notConnected
        }
        
        if appState == .active {
            cancelBackgroundWork()
        }
        
        if appState == .background {
            if webSocket.isConnected {
                disconnectInBackground()
            } else {
                disconnect()
                return .notConnected
            }
        }
        
        if case .message(let response) = event,
            case let .healthCheck(connectionId, healthCheckUser) = response.event,
            let user = healthCheckUser {
            lastConnectionId = connectionId
            handshakeTimer.resume()
            logger?.log("🥰 Connected with id: \(connectionId)")
            return .connected(connectionId, user)
            
        } else if lastJSONError != nil {
            return nil
        }
        
        if appState == .active, !webSocket.isConnected, lastJSONError == nil {
            reconnect()
            return .connecting
        }
        
        switch event {
        case .connected:
            logger?.log("WebSocket connected. Waiting for the first health check message...")
            return .connecting
            
        case .disconnected(let error):
            return isTokenExpired() ? nil : disconnected(error)
            
        default:
            return nil
        }
    }
    
    func parseMessage(_ message: String) -> Response? {
        if lastMessageHashValue == message.hashValue, let response = lastMessageResponse {
            return response
        }
        
        guard let data = message.data(using: .utf8) else {
            logger?.log("📦 Can't get a data from the message: \(message)", level: .error)
            lastMessageResponse = nil
            return nil
        }
        
        lastJSONError = nil
        
        if let errorContainer = try? JSONDecoder.default.decode(ErrorContainer.self, from: data) {
            lastJSONError = errorContainer.error
            lastMessageResponse = nil
            logger?.log(data, forceToShowData: true)
            return nil
        }
        
        do {
            let lastMessageResponse = try JSONDecoder.default.decode(Response.self, from: data)
            self.lastMessageResponse = lastMessageResponse
            lastMessageHashValue = message.hashValue
            consecutiveFailures = 0
            
            if case .healthCheck = lastMessageResponse.event.type {} else {
                if let cid = lastMessageResponse.cid {
                    logger?.log("\(lastMessageResponse.event.type) 🆔 \(cid)")
                } else {
                    logger?.log("\(lastMessageResponse.event.type)")
                }
            }
            
            logger?.log(data)
            return lastMessageResponse
            
        } catch {
            logger?.log(data, forceToShowData: true)
            logger?.log(error, message: "🦄😡 Decode response")
            lastMessageResponse = nil
            lastMessageHashValue = 0
        }
        
        return nil
    }
}
