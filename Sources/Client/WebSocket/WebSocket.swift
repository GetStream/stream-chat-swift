//
//  WebSocket.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 18/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import Starscream

/// A web socket client.
final class WebSocket {
    static var pingTimeInterval = 25
    
    /// A WebSocket connection callback.
    var onConnect: Client.OnConnect = { _ in }
    private var onEventObservers = [String: Client.OnEvent]()
    private let webSocket: Starscream.WebSocket
    private let callbackQueue: DispatchQueue?
    private let stayConnectedInBackground: Bool
    private let logger: ClientLogger?
    private var consecutiveFailures: TimeInterval = 0
    private var shouldReconnect = false
    private var isReconnecting = false
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private let webSocketInitiated: Bool
    private(set) var lastConnectionId: String?
    private(set) var lastJSONError: ClientErrorResponse?
    
    private(set) var connection = Connection.notConnected {
        didSet {
            let lastConnection = connection
            performInCallbackQueue { [weak self] in self?.onConnect(lastConnection) }
        }
    }
    
    private lazy var handshakeTimer =
        RepeatingTimer(timeInterval: .seconds(WebSocket.pingTimeInterval), queue: webSocket.callbackQueue) { [weak self] in
            self?.logger?.log("🏓➡️")
            self?.webSocket.write(ping: .empty)
    }
    
    /// Checks if the web socket is connected and `connectionId` is not nil.
    var isConnected: Bool { lastConnectionId != nil && webSocket.isConnected }
    
    init(_ urlRequest: URLRequest,
         callbackQueue: DispatchQueue? = nil,
         stayConnectedInBackground: Bool = true,
         logger: ClientLogger? = nil) {
        self.callbackQueue = callbackQueue
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
        callbackQueue = nil
        stayConnectedInBackground = false
        logger = nil
    }
    
    deinit {
        if isConnected {
            logger?.log("💔 Disconnect on deinit")
            disconnect(reason: "Deallocating WebSocket")
        }
    }
    
    private func performInCallbackQueue(execute block: @escaping () -> Void) {
        if let callbackQueue = callbackQueue {
            callbackQueue.async(execute: block)
        } else {
            block()
        }
    }
}

// MARK: - Connection

extension WebSocket {
    
    /// Connect to websocket.
    /// - Note:
    /// - Skip if the Internet is not available.
    /// - Skip if it's already connected.
    /// - Skip if it's reconnecting.
    func connect() {
        guard webSocketInitiated else {
            return
        }
        
        cancelBackgroundWork()
        
        if connection == .connecting || isReconnecting || isConnected {
            logger?.log("Skip connecting: "
                + "isConnected = \(webSocket.isConnected), "
                + "isReconnecting = \(isReconnecting), "
                + "isConnecting = \(connection == .connecting)")
            return
        }
        
        logger?.log("Connecting...")
        logger?.log(webSocket.request)
        connection = .connecting
        shouldReconnect = true
        
        DispatchQueue.main.async(execute: webSocket.connect)
    }
    
    private func reconnect() {
        guard !isReconnecting else {
            return
        }
        
        isReconnecting = true
        let maxDelay: TimeInterval = min(500 + consecutiveFailures * 2000, 25000) / 1000
        let minDelay: TimeInterval = min(max(250, (consecutiveFailures - 1) * 2000), 25000) / 1000
        consecutiveFailures += 1
        let delay = minDelay + TimeInterval.random(in: 0...(maxDelay - minDelay))
        logger?.log("⏳ Reconnect in \(delay) sec")
        
        webSocket.callbackQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.isReconnecting = false
            self?.connect()
        }
    }
    
    func disconnectInBackground() {
        webSocket.callbackQueue.async(execute: disconnectInBackgroundInWebSocketQueue)
    }
    
    private func disconnectInBackgroundInWebSocketQueue() {
        guard stayConnectedInBackground else {
            disconnect(reason: "Going into background, stayConnectedInBackground is disabled")
            return
        }
        
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
        }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.disconnect(reason: "Processing finished in background")
            self?.backgroundTask = .invalid
        }
        
        if backgroundTask == .invalid {
            disconnect(reason: "Can't create a background task")
        }
    }
    
    private func cancelBackgroundWork() {
        logger?.log("Cancelling background work...")
        
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
            logger?.log("💜 Background mode off")
        }
    }
    
    func disconnect(reason: String) {
        guard webSocketInitiated else {
            return
        }
        
        shouldReconnect = false
        consecutiveFailures = 0
        clearStateAfterDisconnect()
        
        if webSocket.isConnected {
            logger?.log("Disconnecting: \(reason)")
            connection = .disconnecting
            webSocket.disconnect(forceTimeout: 0)
        } else {
            logger?.log("Skip disconnecting: WebSocket was not connected")
            connection = .disconnected(nil)
        }
    }
    
    func subscribe(forEvents eventTypes: Set<EventType> = Set(EventType.allCases),
                   callback: @escaping Client.OnEvent) -> Cancellable {
        let subscription = Subscription { [weak self] uuid in
            self?.webSocket.callbackQueue.async {
                self?.onEventObservers[uuid] = nil
            }
        }
        
        let handler: Client.OnEvent = { event in
            guard eventTypes.contains(event.type) else {
                return
            }
            
            callback(event)
        }
        
        webSocket.callbackQueue.async { [weak self] in
            self?.onEventObservers[subscription.uuid] = handler
        }
        
        return subscription
    }
    
    private func clearStateAfterDisconnect() {
        logger?.log("Clearing state after disconnect...")
        handshakeTimer.suspend()
        lastConnectionId = nil
        cancelBackgroundWork()
    }
}

// MARK: - Web Socket Delegate

extension WebSocket: WebSocketDelegate {
    
    func websocketDidConnect(socket: Starscream.WebSocketClient) {
        logger?.log("❤️ Connected. Waiting for the current user data and connectionId...")
        connection = .connecting
    }
    
    func websocketDidDisconnect(socket: Starscream.WebSocketClient, error: Error?) {
        parseDisconnect(error)
    }
    
    func websocketDidReceiveMessage(socket: Starscream.WebSocketClient, text: String) {
        guard let event = parseEvent(with: text) else {
            return
        }
        
        if case let .healthCheck(connectionId, _) = event {
            lastConnectionId = connectionId
            handshakeTimer.resume()
            logger?.log("🥰 Connected")
            
            onEventObservers.values.forEach({ $0(event) })
            
            performInCallbackQueue { [weak self] in
                self?.connection = .connected
            }
            
            return
        }
        
        if isConnected {
            onEventObservers.values.forEach({ $0(event) })
        }
    }
    
    func websocketDidReceiveData(socket: Starscream.WebSocketClient, data: Data) {}

    // MARK: Parsing Events
    
    private func parseDisconnect(_ error: Error? = nil) {
        logger?.log("Parsing WebSocket disconnect... (error: \(error?.localizedDescription ?? "<nil>"))")
        clearStateAfterDisconnect()
        
        if let lastJSONError = lastJSONError, lastJSONError.code == ClientErrorResponse.tokenExpiredErrorCode {
            logger?.log("Disconnected. 🀄️ Token is expired")
            connection = .disconnected(ClientError.expiredToken)
            return
        }
        
        guard let error = error else {
            logger?.log("💔 Disconnected")
            connection = .disconnected(nil)
            
            if shouldReconnect {
                reconnect()
            } else {
                consecutiveFailures = 0
            }
            
            return
        }
        
        if isStopError(error) {
            logger?.log("💔 Disconnected with Stop code")
            consecutiveFailures = 0
            return
        }
        
        logger?.log(error, message: "💔😡 Disconnected by error")
        logger?.log(lastJSONError)
        ClientLogger.showConnectionAlert(error, jsonError: lastJSONError)
        connection = .disconnected(error)
        
        if shouldReconnect {
            reconnect()
        }
    }
    
    private func isStopError(_ error: Swift.Error) -> Bool {
        guard InternetConnection.shared.isAvailable else {
            return true
        }
        
        if let lastJSONError = lastJSONError, lastJSONError.code == 1000 {
            return true
        }
        
        if let wsError = error as? WSError, wsError.code == 1000 {
            return true
        }
        
        return false
    }
    
    private func parseEvent(with message: String) -> Event? {
        guard let data = message.data(using: .utf8) else {
            logger?.log("📦 Can't get a data from the message: \(message)", level: .error)
            return nil
        }
        
        lastJSONError = nil
        
        do {
            let event = try JSONDecoder.default.decode(Event.self, from: data)
            consecutiveFailures = 0
            
            if case .pong = event {
                logger?.log("⬅️🏓")
                return nil
            }
            
            if let logger = logger {
                var userId = ""
                
                if let user = event.user {
                    userId = user.isAnonymous ? " 👺" : " 👤 \(user.id)"
                }
                
                if let cid = event.cid {
                    logger.log("\(event.type) 🆔 \(cid)\(userId)")
                } else {
                    logger.log("\(event.type)\(userId)")
                }
                
                logger.log(data)
            }
            
            return event
            
        } catch {
            if let errorContainer = try? JSONDecoder.default.decode(ErrorContainer.self, from: data) {
                lastJSONError = errorContainer.error
            } else {
                logger?.log(error, message: "😡 Decode response")
            }
            
            logger?.log(data, forceToShowData: true)
        }
        
        return nil
    }
}

/// WebSocket Error
private struct ErrorContainer: Decodable {
    /// A server error was recieved.
    let error: ClientErrorResponse
}
