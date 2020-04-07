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
    private var onClientEventObservers = [String: OnEvent<ClientEvent>]()
    private var onChannelEventObservers = [String: OnEvent<ChannelEvent>]()
    private let webSocket: Starscream.WebSocket
    private let callbackQueue: DispatchQueue?
    private let stayConnectedInBackground: Bool
    private let logger: ClientLogger?
    private var consecutiveFailures: TimeInterval = 0
    private var shouldReconnect = false
    private var isReconnecting = false
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private let webSocketInitiated: Bool
    private(set) var connectionId: String?
    private(set) var eventError: ClientErrorResponse?
    
    private(set) var connectionState = ConnectionState.notConnected {
        didSet {
            let lastConnection = connectionState
            performInCallbackQueue { [weak self] in self?.onConnect(lastConnection) }
        }
    }
    
    private lazy var handshakeTimer =
        RepeatingTimer(timeInterval: .seconds(WebSocket.pingTimeInterval), queue: webSocket.callbackQueue) { [weak self] in
            self?.logger?.log("🏓➡️")
            self?.webSocket.write(ping: .empty)
    }
    
    /// Checks if the web socket is connected and `connectionId` is not nil.
    var isConnected: Bool { connectionId != nil && webSocket.isConnected }
    
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
        
        if connectionState == .connecting || isReconnecting || isConnected {
            logger?.log("Skip connecting: "
                + "isConnected = \(webSocket.isConnected), "
                + "isReconnecting = \(isReconnecting), "
                + "isConnecting = \(connectionState == .connecting)")
            return
        }
        
        logger?.log("Connecting...")
        logger?.log(webSocket.request)
        connectionState = .connecting
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
            connectionState = .disconnecting
            webSocket.disconnect(forceTimeout: 0)
        } else {
            logger?.log("Skip disconnecting: WebSocket was not connected")
            connectionState = .disconnected(nil)
        }
    }
    
    private func clearStateAfterDisconnect() {
        logger?.log("Clearing state after disconnect...")
        handshakeTimer.suspend()
        connectionId = nil
        cancelBackgroundWork()
    }
}

// MARK: - Subscriptions

extension WebSocket {
    func subscribe<T: EventType, E: Event>(forEvents eventTypes: Set<T> = Set(T.allCases),
                                           cid: ChannelId? = nil,
                                           _ callback: @escaping OnEvent<E>) -> Cancellable where E.T == T {
        let subscription = Subscription { [weak self] uuid in
            self?.webSocket.callbackQueue.async {
                if E.self is ChannelEvent.Type {
                    self?.onChannelEventObservers[uuid] = nil
                } else {
                    self?.onClientEventObservers[uuid] = nil
                }
            }
        }
        
        let handler: OnEvent<E> = { event in
            if eventTypes.contains(event.type) {
                // Filter channel events by cid, if needed.
                if let cid = cid, event.cid != cid {
                    return
                }
                
                callback(event)
            }
        }
        
        webSocket.callbackQueue.async { [weak self] in
            if let handler = handler as? OnEvent<ChannelEvent> {
                self?.onChannelEventObservers[subscription.uuid] = handler
            } else if let handler = handler as? OnEvent<ClientEvent> {
                self?.onClientEventObservers[subscription.uuid] = handler
            }
        }
        
        return subscription
    }
}

// MARK: - Starscream Web Socket Delegate

extension WebSocket: WebSocketDelegate {
    
    private struct EventTypeResponse: Decodable {
        let type: String
    }
    
    private struct ErrorContainer: Decodable {
        /// A server error was recieved.
        let error: ClientErrorResponse
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        logger?.log("❤️ Connected. Waiting for the current user data and connectionId...")
        connectionState = .connecting
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        guard let data = text.data(using: .utf8) else {
            logger?.log("📦 Can't get a data from the message: \(text)", level: .error)
            return
        }
        
        guard let eventTypeResponse = try? JSONDecoder.stream.decode(EventTypeResponse.self, from: data) else {
            logger?.log("📦 Can't get event type from the message: \(text)", level: .error)
            return
        }
        
        // Parse channel events.
        if ChannelEventType(rawValue: eventTypeResponse.type) != nil, let channelEvent: ChannelEvent = parseEvent(data) {
            onChannelEventObservers.values.forEach({ $0(channelEvent) })
            return
        }
        
        // Parse client events.
        guard let clientEvent: ClientEvent = parseEvent(data) else {
            return
        }
        
        if case .pong = clientEvent {
            logger?.log("⬅️🏓")
            return
        }
        
        if case let .healthCheck(user, connectionId) = clientEvent {
            logger?.log("🥰 Connected")
            self.connectionId = connectionId
            handshakeTimer.resume()
            let userConnection = UserConnection(user: user, connectionId: connectionId)
            performInCallbackQueue { [weak self] in self?.connectionState = .connected(userConnection) }
        }
        
        onClientEventObservers.values.forEach({ $0(clientEvent) })
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {}
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        logger?.log("Parsing WebSocket disconnect... (error: \(error?.localizedDescription ?? "<nil>"))")
        clearStateAfterDisconnect()
        
        if let eventError = eventError, eventError.code == ClientErrorResponse.tokenExpiredErrorCode {
            logger?.log("Disconnected. 🀄️ Token is expired")
            connectionState = .disconnected(ClientError.expiredToken)
            return
        }
        
        guard let error = error else {
            logger?.log("💔 Disconnected")
            connectionState = .disconnected(nil)
            
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
        logger?.log(eventError)
        ClientLogger.showConnectionAlert(error, jsonError: eventError)
        connectionState = .disconnected(error)
        
        if shouldReconnect {
            reconnect()
        }
    }
    
    // MARK: Parsing Events
    
    private func parseEvent<T: Event>(_ data: Data) -> T? {
        eventError = nil
        
        do {
            let event = try JSONDecoder.default.decode(T.self, from: data)
            consecutiveFailures = 0
            
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
                eventError = errorContainer.error
            } else {
                logger?.log(error, message: "😡 Decode response")
            }
            
            logger?.log(data, forceToShowData: true)
        }
        
        return nil
    }
    
    private func isStopError(_ error: Swift.Error) -> Bool {
        guard InternetConnection.shared.isAvailable else {
            return true
        }
        
        if let eventError = eventError, eventError.code == 1000 {
            return true
        }
        
        if let wsError = error as? WSError, wsError.code == 1000 {
            return true
        }
        
        return false
    }
}
