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
import RxSwift
import RxAppState

/// A web socket client.
public final class WebSocket {
    private static let maxBackgroundTime: TimeInterval = 300
    
    let webSocket: Starscream.WebSocket
    let stayConnectedInBackground: Bool
    let logger: ClientLogger?
    
    private(set) var lastJSONError: ClientErrorResponse?
    private(set) var lastConnectionId: String?
    private var consecutiveFailures: TimeInterval = 0
    private var isReconnecting = false
    private var goingToDisconnect: DispatchWorkItem?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var lastMessageHashValue: Int = 0
    private var lastMessageResponse: Response?
    private let webSocketInitiated: Bool

    private lazy var handshakeTimer = RepeatingTimer(timeInterval: .seconds(30), queue: webSocket.callbackQueue) { [weak self] in
        self?.logger?.log("🏓", level: .info)
        self?.webSocket.write(ping: Data())
    }
    
    /// Check if the web socket is connected.
    public var isConnected: Bool {
        return lastConnectionId != nil && webSocket.isConnected
    }
    
    /// An observable event response.
    private(set) lazy var rxResponse = rx.setupResponse()
    
    init(_ urlRequest: URLRequest, stayConnectedInBackground: Bool = true, logger: ClientLogger? = nil) {
        self.stayConnectedInBackground = stayConnectedInBackground
        self.logger = logger
        webSocket = Starscream.WebSocket(request: urlRequest)
        webSocket.callbackQueue = DispatchQueue(label: "io.getstream.Chat.WebSocket", qos: .userInitiated)
        webSocketInitiated = true
    }
    
    init() {
        webSocket = .init(url: BaseURL.placeholderURL)
        webSocketInitiated = false
        stayConnectedInBackground = false
        logger = nil
    }
    
    deinit {
        disconnect()
    }
    
    /// Subscribe for websocket response.
    /// - Parameter completion: a completion block (see `ClientCompletion`).
    /// - Returns: a subscription.
    public func response(_ completion: @escaping ClientCompletion<WebSocket.Response>) -> Subscription {
        return rxResponse.bind(to: completion)
    }
}

// MARK: - Connection

extension WebSocket {
    
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
        
        logger?.log("❤️ Connecting...")
        logger?.log(webSocket.request)
        DispatchQueue.main.async(execute: webSocket.connect)
    }
    
    func reconnect() {
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
    
    func disconnectInBackground() {
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
    
    func cancelBackgroundWork() {
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
        
        DispatchQueue.main.async {
            if UIApplication.shared.appState == .background {
                InternetConnection.shared.stopObserving()
            }
        }
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
            
            if !willReconnectAfterError(error) {
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
    
    private func willReconnectAfterError(_ error: Swift.Error) -> Bool {
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

// MARK: - Parsing

extension WebSocket {
    
    func parseConnection(appState: AppState, isInternetAvailable: Bool, event: WebSocketEvent) -> Connection? {
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
        
        if case .message = event {
            if let response = parseMessage(event),
                case let .healthCheck(connectionId, healthCheckUser) = response.event,
                let user = healthCheckUser {
                lastConnectionId = connectionId
                handshakeTimer.resume()
                Client.shared.unreadCountAtomic.set((user.channelsUnreadCount, user.messagesUnreadCount))
                logger?.log("🥰 Connected with id: \(connectionId)")
                return .connected(connectionId, user)
            } else if lastJSONError != nil {
                return nil
            }
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
            break
        }
        
        return nil
    }
    
    func parseMessage(_ event: WebSocketEvent) -> Response? {
        guard case .message(let message) = event else {
            lastMessageResponse = nil
            return nil
        }
        
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
