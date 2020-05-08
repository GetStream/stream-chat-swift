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
    private let onEvent: (Event) -> Void
    private var onEventObservers = [String: Client.OnEvent]()
    private let webSocket: Starscream.WebSocket
    private let stayConnectedInBackground: Bool
    private let logger: ClientLogger?
    private var consecutiveFailures: TimeInterval = 0
    private var shouldReconnect = false
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private let webSocketInitiated: Bool
    private(set) var connectionId: String?
    private(set) var eventError: ClientErrorResponse?
    
    var connectionState: ConnectionState { connectionStateAtomic.get() }
    
    private lazy var connectionStateAtomic =
        Atomic<ConnectionState>(.notConnected, callbackQueue: nil) { [weak self] connectionState, _ in
            self?.publishEvent(.connectionChanged(connectionState))
    }
    
    private lazy var handshakeTimer =
        RepeatingTimer(timeInterval: .seconds(WebSocket.pingTimeInterval), queue: webSocket.callbackQueue) { [weak self] in
            self?.logger?.log("🏓➡️", level: .info)
            self?.webSocket.write(ping: .empty)
    }
    
    /// Checks if the web socket is connected and `connectionId` is not nil.
    var isConnected: Bool { connectionId != nil && webSocket.isConnected }
    
    init(_ urlRequest: URLRequest,
         stayConnectedInBackground: Bool = true,
         logger: ClientLogger? = nil,
         onEvent: @escaping (Event) -> Void = { _ in }) {
        self.stayConnectedInBackground = stayConnectedInBackground
        self.logger = logger
        self.onEvent = onEvent
        webSocket = Starscream.WebSocket(request: urlRequest)
        webSocket.callbackQueue = DispatchQueue(label: "io.getstream.Chat.WebSocket", qos: .userInitiated)
        webSocketInitiated = true
        webSocket.delegate = self
    }
    
    init() {
        webSocket = .init(url: BaseURL.placeholderURL)
        webSocketInitiated = false
        stayConnectedInBackground = false
        logger = nil
        onEvent = { _ in }
    }
    
    deinit {
        if isConnected {
            logger?.log("💔 Disconnect on deinit")
            disconnect(reason: "Deallocating WebSocket")
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
        
        if isConnected || connectionState == .connecting || connectionState == .reconnecting {
            logger?.log("Skip connecting: "
                + "isConnected = \(webSocket.isConnected), "
                + "isReconnecting = \(connectionState == .reconnecting), "
                + "isConnecting = \(connectionState == .connecting)")
            return
        }
        
        logger?.log("Connecting...")
        logger?.log(webSocket.request)
        connectionStateAtomic.set(.connecting)
        shouldReconnect = true
        
        DispatchQueue.main.async(execute: webSocket.connect)
    }
    
    private func reconnect() {
        guard connectionState != .reconnecting else {
            return
        }
        
        connectionStateAtomic.set(.reconnecting)
        let maxDelay: TimeInterval = min(500 + consecutiveFailures * 2000, 25000) / 1000
        let minDelay: TimeInterval = min(max(250, (consecutiveFailures - 1) * 2000), 25000) / 1000
        consecutiveFailures += 1
        let delay = minDelay + TimeInterval.random(in: 0...(maxDelay - minDelay))
        logger?.log("⏳ Reconnect in \(delay) sec")
        
        webSocket.callbackQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.connectionStateAtomic.set(.connecting)
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
            connectionStateAtomic.set(.disconnecting)
            webSocket.disconnect(forceTimeout: 0)
        } else {
            logger?.log("Skip disconnecting: WebSocket was not connected")
            connectionStateAtomic.set(.disconnected(nil))
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
    
    func subscribe(forEvents eventTypes: Set<EventType> = Set(EventType.allCases),
                   callback: @escaping Client.OnEvent) -> Cancellable {
        let subscription = Subscription { [weak self] uuid in
            self?.webSocket.callbackQueue.async {
                self?.onEventObservers[uuid] = nil
            }
        }
        
        let handler: Client.OnEvent = { event in
            if eventTypes.contains(event.type) {
                callback(event)
            }
        }
        
        webSocket.callbackQueue.async { [weak self] in
            self?.onEventObservers[subscription.uuid] = handler
            
            // Reply the last connectoin state.
            if eventTypes.contains(.connectionChanged), let connectionState = self?.connectionState {
                handler(.connectionChanged(connectionState))
            }
        }
        
        return subscription
    }
    
    private func publishEvent(_ event: Event) {
        webSocket.callbackQueue.async { [weak self] in
            self?.onEvent(event)
            self?.onEventObservers.forEach({ $0.value(event) })
        }
    }
}

// MARK: - Web Socket Delegate

extension WebSocket: WebSocketDelegate {
    
    func websocketDidConnect(socket: Starscream.WebSocketClient) {
        logger?.log("❤️ Connected. Waiting for the current user data and connectionId...")
        connectionStateAtomic.set(.connecting)
    }
    
    func websocketDidReceiveMessage(socket: Starscream.WebSocketClient, text: String) {
        guard let event = parseEvent(with: text) else {
            return
        }
        
        switch event {
        case let .healthCheck(user, connectionId):
            logger?.log("🥰 Connected")
            self.connectionId = connectionId
            handshakeTimer.resume()
            connectionStateAtomic.set(.connected(UserConnection(user: user, connectionId: connectionId)))
            return
            
        case let .messageNew(message, _, _, _) where message.user.isMuted:
            logger?.log("Skip a message (\(message.id)) from muted user (\(message.user.id)): \(message.textOrArgs)", level: .info)
            return
        case let .typingStart(user, _, _), let .typingStop(user, _, _):
            if user.isMuted {
                logger?.log("Skip typing events from muted user (\(user.id))", level: .info)
                return
            }
        default:
            break
        }
        
        if isConnected {
            publishEvent(event)
        }
    }
    
    func websocketDidReceiveData(socket: Starscream.WebSocketClient, data: Data) {}
    
    func websocketDidDisconnect(socket: Starscream.WebSocketClient, error: Error?) {
        logger?.log("Parsing WebSocket disconnect... (error: \(error?.localizedDescription ?? "<nil>"))")
        clearStateAfterDisconnect()
        
        if let eventError = eventError, eventError.code == ClientErrorResponse.tokenExpiredErrorCode {
            logger?.log("Disconnected. 🀄️ Token is expired")
            connectionStateAtomic.set(.disconnected(ClientError.expiredToken))
            return
        }
        
        guard let error = error else {
            logger?.log("💔 Disconnected")
            connectionStateAtomic.set(.disconnected(nil))
            
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
        connectionStateAtomic.set(.disconnected(.websocketDisconnectError(error)))
        
        if shouldReconnect {
            reconnect()
        }
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
    
    private func parseEvent(with message: String) -> Event? {
        guard let data = message.data(using: .utf8) else {
            logger?.log("📦 Can't get a data from the message: \(message)", level: .error)
            return nil
        }
        
        eventError = nil
        
        do {
            let event = try JSONDecoder.default.decode(Event.self, from: data)
            consecutiveFailures = 0
            
            // Skip pong events.
            if case .pong = event {
                logger?.log("⬅️🏓", level: .info)
                return nil
            }
            
            // Log event.
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
}

/// WebSocket Error
private struct ErrorContainer: Decodable {
    /// A server error was recieved.
    let error: ClientErrorResponse
}
