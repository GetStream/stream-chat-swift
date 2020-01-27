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

/// A web socket client.
public final class WebSocket {
    private static let maxBackgroundTime: TimeInterval = 300
    static var pingTimeInterval = 30
    
    /// A WebSocket connection callback.
    var onConnect: Client.OnConnect = { _ in }
    /// A WebSocket events callback.
    var onEvent: Client.OnEvent = { _ in }
    
    private let webSocket: Starscream.WebSocket
    private let callbackQueue: DispatchQueue?
    private let stayConnectedInBackground: Bool
    private let logger: ClientLogger?
    private var consecutiveFailures: TimeInterval = 0
    private var isReconnecting = false
    private var goingToDisconnect: DispatchWorkItem?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private let webSocketInitiated: Bool
    private(set) var lastConnectionId: String?
    private(set) var lastJSONError: ClientErrorResponse?
    
    private lazy var handshakeTimer = RepeatingTimer(timeInterval: .seconds(WebSocket.pingTimeInterval),
                                                     queue: webSocket.callbackQueue) { [weak self] in
                                                        self?.logger?.log("🏓", level: .info)
                                                        self?.webSocket.write(ping: .empty)
    }
    
    /// Checks if the web socket is connected and `connectionId` is not nil.
    var isConnected: Bool {
        return lastConnectionId != nil && webSocket.isConnected
    }
    
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
            disconnect()
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
        
        logger?.log("Connecting...")
        logger?.log(webSocket.request)
        DispatchQueue.main.async(execute: webSocket.connect)
        performInCallbackQueue { [weak self] in self?.onConnect(.connecting) }
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
            logger?.log("💜 Background mode on")
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
            logger?.log("💜 Background mode off")
        }
    }
    
    func disconnect() {
        guard webSocketInitiated else {
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
    
    private func disconnectedNoInternet() {
        logger?.log("💔🕸 Disconnected: No Internet")
        clearStateAfterDisconnect()
        consecutiveFailures = 0
    }
    
    private func disconnected(_ error: Error? = nil) -> Connection {
        logger?.log("💔🤔 Disconnected")
        clearStateAfterDisconnect()
        
        if let error = error {
            var errorMessage = "💔😡 Disconnected by error"
            
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
        logger?.log("❤️ Connected. Waiting for the current user data and connectionId...")
        performInCallbackQueue { [weak self] in self?.onConnect(.connecting) }
    }
    
    public func websocketDidDisconnect(socket: Starscream.WebSocketClient, error: Error?) {
        guard let lastJSONError = lastJSONError, lastJSONError.code == ClientErrorResponse.tokenExpiredErrorCode else {
            logger?.log("💔 Disconnected")
            performInCallbackQueue { [weak self] in self?.onConnect(.disconnected(error)) }
            return
        }
        
        logger?.log("Disconnected. 🀄️ Token is expired")
        performInCallbackQueue { [weak self] in self?.onConnect(.disconnected(ClientError.expiredToken)) }
    }
    
    public func websocketDidReceiveMessage(socket: Starscream.WebSocketClient, text: String) {
        guard let event = parseEvent(with: text) else {
            return
        }
        
        if case .pong = event {
            return
        }
        
        if case let .healthCheck(connectionId, _) = event {
            lastConnectionId = connectionId
            handshakeTimer.resume()
            logger?.log("🥰 Connected")
            
            performInCallbackQueue { [weak self] in
                self?.onEvent(event)
                self?.onConnect(.connected)
            }
            
            return
        }
        
        if isConnected {
            performInCallbackQueue { [weak self] in self?.onEvent(event) }
        }
    }
    
    public func websocketDidReceiveData(socket: Starscream.WebSocketClient, data: Data) {}
}

// MARK: - Parsing

extension WebSocket {
    
    private func parseEvent(with message: String) -> Event? {
        guard let data = message.data(using: .utf8) else {
            logger?.log("📦 Can't get a data from the message: \(message)", level: .error)
            return nil
        }
        
        lastJSONError = nil
        
        do {
            let event = try JSONDecoder.default.decode(Event.self, from: data)
            consecutiveFailures = 0
            
            if let logger = logger {
                if case .pong = event.type {} else {
                    var userId = ""
                    
                    if let user = event.user {
                        userId = " 👤 \(user.id)"
                    }
                    
                    if let cid = event.cid {
                        logger.log("\(event.type) 🆔 \(cid)\(userId)")
                    } else {
                        logger.log("\(event.type)\(userId)")
                    }
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
struct ErrorContainer: Decodable {
    /// A server error was recieved.
    public let error: ClientErrorResponse
}
