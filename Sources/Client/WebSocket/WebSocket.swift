//
//  WebSocket.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 18/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

/// A web socket client.
final class WebSocket {
    /// The time interval to ping connection to keep it alive.
    static let pingTimeInterval: TimeInterval = 25
    
    /// A WebSocket connection callback.
    private let onEvent: (Event) -> Void
    private var onEventObservers = [String: Client.OnEvent]()
    private var provider: WebSocketProvider
    private let options: WebSocketOptions
    private let logger: ClientLogger?
    private var consecutiveFailures: TimeInterval = 0
    private var shouldReconnect = false
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private(set) var connectionId: String?
    private(set) var eventError: ClientErrorResponse?
    
    var connectionState: ConnectionState { connectionStateAtomic.get() }
    
    private lazy var connectionStateAtomic =
        Atomic<ConnectionState>(.notConnected, callbackQueue: nil) { [weak self] connectionState, _ in
            self?.publishEvent(.connectionChanged(connectionState))
    }
    
    private lazy var handshakeTimer =
        Timer.scheduleRepeating(timeInterval: WebSocket.pingTimeInterval,
                                queue: provider.callbackQueue) { [weak self] in
            self?.logger?.log("🏓➡️", level: .info)
            self?.provider.sendPing()
        }
    
    private let Timer: Timer.Type
    
    /// Checks if the web socket is connected and `connectionId` is not nil.
    var isConnected: Bool { connectionId != nil && provider.isConnected }
    
    init(_ provider: WebSocketProvider,
         options: WebSocketOptions,
         logger: ClientLogger? = nil,
         timerType: Timer.Type = DefaultTimer.self,
         onEvent: @escaping (Event) -> Void = { _ in }) {
        
        self.provider = provider
        self.options = options
        self.logger = logger
        self.onEvent = onEvent
        self.Timer = timerType
        self.provider.delegate = self
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
    ///     - Skip if the Internet is not available.
    ///     - Skip if it's already connected.
    ///     - Skip if it's reconnecting.
    func connect() {
        cancelBackgroundWork()
        
        if isConnected || connectionState == .connecting || connectionState == .reconnecting {
            if let logger = logger {
                let reasons = [(isConnected ? " isConnected with connectionId = \(connectionId ?? "n/a")" : nil),
                               (connectionState == .reconnecting ? " isReconnecting" : nil),
                               (connectionState == .connecting ? "isConnecting" : nil),
                               (provider.isConnected ? "\(provider).isConnected" : nil)]
                
                logger.log("SKIP connect: \(reasons.compactMap({ $0 }).joined(separator: ", "))")
            }
            
            return
        }
        
        if provider.isConnected {
            provider.disconnect()
        }
        
        logger?.log("Connecting...")
        logger?.log(provider.request)
        connectionStateAtomic.set(.connecting)
        shouldReconnect = true
        
        DispatchQueue.main.async(execute: provider.connect)
    }
    
    private func reconnect() {
        guard connectionState != .reconnecting else {
            return
        }
        
        connectionStateAtomic.set(.reconnecting)
        let maxDelay: TimeInterval = min(0.5 + consecutiveFailures * 2, 25)
        let minDelay: TimeInterval = min(max(0.25, (consecutiveFailures - 1) * 2), 25)
        consecutiveFailures += 1
        let delay = TimeInterval.random(in: minDelay...maxDelay)
        logger?.log("⏳ Reconnect in \(delay) sec")
        
        Timer.schedule(timeInterval: delay, queue: provider.callbackQueue) { [weak self] in
            self?.connectionStateAtomic.set(.notConnected)
            self?.connect()
        }
    }
    
    func disconnectInBackground() {
        provider.callbackQueue.async(execute: disconnectInBackgroundInWebSocketQueue)
    }
    
    private func disconnectInBackgroundInWebSocketQueue() {
        guard options.contains(.stayConnectedInBackground) else {
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
        shouldReconnect = false
        consecutiveFailures = 0
        clearStateAfterDisconnect()
        
        if provider.isConnected {
            logger?.log("Disconnecting: \(reason)")
            connectionStateAtomic.set(.disconnecting)
            provider.disconnect()
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
            self?.provider.callbackQueue.async {
                self?.onEventObservers[uuid] = nil
            }
        }
        
        let handler: Client.OnEvent = { event in
            if eventTypes.contains(event.type) {
                callback(event)
            }
        }
        
        provider.callbackQueue.async { [weak self] in
            self?.onEventObservers[subscription.uuid] = handler
            
            // Reply the last connectoin state.
            if eventTypes.contains(.connectionChanged), let connectionState = self?.connectionState {
                handler(.connectionChanged(connectionState))
            }
        }
        
        return subscription
    }
    
    private func publishEvent(_ event: Event) {
        provider.callbackQueue.async { [weak self] in
            self?.onEvent(event)
            self?.onEventObservers.forEach({ $0.value(event) })
        }
    }
}

// MARK: - Web Socket Delegate

extension WebSocket: WebSocketProviderDelegate {
    
    func websocketDidConnect() {
        logger?.log("❤️ Connected. Waiting for the current user data and connectionId...")
        connectionStateAtomic.set(.connecting)
    }
    
    func websocketDidReceiveMessage(_ message: String) {
        guard let event = parseEvent(with: message) else {
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
    
    func websocketDidDisconnect(error: WebSocketProviderError?) {
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
            connectionStateAtomic.set(.disconnected(.websocketDisconnectError(error)))
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
    
    private func isStopError(_ error: WebSocketProviderError) -> Bool {
        guard InternetConnection.shared.isAvailable else {
            return true
        }
        
        if let eventError = eventError, eventError.code == WebSocketProviderError.stopErrorCode {
            return true
        }
        
        if error.code == WebSocketProviderError.stopErrorCode {
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

struct WebSocketOptions: OptionSet {
    let rawValue: Int
    
    static let stayConnectedInBackground = WebSocketOptions(rawValue: 1 << 0)
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// WebSocket Error
private struct ErrorContainer: Decodable {
    /// A server error was recieved.
    let error: ClientErrorResponse
}
