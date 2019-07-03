//
//  WebSocket.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 18/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import Starscream
import Reachability
import RxSwift
import RxStarscream
import RxReachability
import RxAppState

final class WebSocket {
    private static let maxBackgroundTime: TimeInterval = 300
    
    let webSocket: Starscream.WebSocket
    private(set) var lastJSONError: Error?
    private(set) var lastConnectionId: String?
    private(set) var consecutiveFailures: TimeInterval = 0
    let logger: ClientLogger?
    var isReconnecting = false
    private var goingToDisconnect: DispatchWorkItem?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    private var lastMessageHashValue: Int = 0
    private var lastMessageResponse: Response?
    
    private lazy var handshakeTimer = RepeatingTimer(timeInterval: .seconds(30), queue: webSocket.callbackQueue) { [weak self] in
        self?.logger?.log("🏓")
        self?.webSocket.write(ping: Data())
    }
    
    private(set) lazy var connection: Observable<WebSocket.Connection> = {
        let app = UIApplication.shared
        
        let webSocketResponse = webSocket.rx.response
            .do(onSubscribed: { [weak self] in self?.reconnect() },
                onDispose: { [weak self] in self?.disconnect() })
        
        return Observable.combineLatest(app.rx.appState.startWith(app.appState),
                                        InternetConnection.shared.isAvailableObservable,
                                        webSocketResponse)
            .map { [weak self] in self?.parseConnection(appState: $0, isInternetAvailable: $1, event: $2) }
            .unwrap()
            .distinctUntilChanged()
            .share(replay: 1)
    }()
    
    private(set) lazy var response: Observable<WebSocket.Response> = Observable
        .combineLatest(webSocket.rx.response, connection.connected())
        .map { [weak self] event, _ in self?.parseMessage(event) }
        .unwrap()
        .share()
    
    init(_ urlRequest: URLRequest, logger: ClientLogger? = nil) {
        self.logger = logger
        webSocket = Starscream.WebSocket(request: urlRequest)
        webSocket.callbackQueue = DispatchQueue(label: "io.getstream.Chat", qos: .userInitiated)
    }
    
    deinit {
        disconnect()
    }
    
    func connect() {
        if webSocket.isConnected || isReconnecting {
           return
        }
        
        logger?.log("❤️", "Connecting...")
        logger?.log(webSocket.request)
        DispatchQueue.main.async(execute: webSocket.connect)
    }
    
    func disconnectInBackground() {
        guard backgroundTask == .invalid else {
            return
        }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.disconnect()
        }
        
        if backgroundTask != .invalid {
            let goingToDisconnect: DispatchWorkItem = DispatchWorkItem { [weak self] in
                self?.disconnect()
                InternetConnection.shared.stopObserving()
            }
            
            webSocket.callbackQueue.asyncAfter(deadline: .now() + WebSocket.maxBackgroundTime, execute: goingToDisconnect)
            self.goingToDisconnect = goingToDisconnect
            logger?.log("💜", "Background mode on")
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
            logger?.log("💜", "Background mode off")
        }
    }
    
    func disconnect() {
        lastConnectionId = nil
        
        if webSocket.isConnected {
            handshakeTimer.suspend()
            webSocket.disconnect()
            logger?.log("💔", "Disconnected")
        }
        
        cancelBackgroundWork()
    }
}

// MARK: - Parsing

extension WebSocket {
    
    private func parseConnection(appState: AppState, isInternetAvailable: Bool, event: WebSocketEvent) -> Connection? {
        guard isInternetAvailable else {
            cancelBackgroundWork()
            lastConnectionId = nil
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
                logger?.log("🥰 Connected")
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
            logger?.log("WebSocket connected")
            return .connecting
            
        case .disconnected(let error):
            logger?.log("💔🤔 Disconnected")
            handshakeTimer.suspend()
            
            if let error = error {
                logger?.log(error, message: "💔😡 Disconnected by error:")
                ClientLogger.showConnectionAlert(error, jsonError: lastJSONError)
            }
            
            if let error = error, willReconnectAfterError(error) {
                consecutiveFailures += 1
            } else {
                consecutiveFailures = 0
            }
            
            return .notConnected
            
        default:
            break
        }
        
        return nil
    }
    
    private func parseMessage(_ event: WebSocketEvent) -> Response? {
        guard case .message(let message) = event else {
            lastMessageResponse = nil
            return nil
        }
        
        if lastMessageHashValue == message.hashValue, let response = lastMessageResponse {
            return response
        }
        
        guard let data = message.data(using: .utf8) else {
            logger?.log("📦", "Can't get a data from the message: \(message)")
            lastMessageResponse = nil
            return nil
        }
        
        logger?.log("📦", data)
        lastJSONError = nil
        
        if let errorContainer = try? JSONDecoder.stream.decode(ErrorContainer.self, from: data) {
            lastJSONError = errorContainer.error
            lastMessageResponse = nil
            return nil
        }
        
        do {
            lastMessageResponse = try JSONDecoder.stream.decode(Response.self, from: data)
            lastMessageHashValue = message.hashValue
            consecutiveFailures = 0
            return lastMessageResponse
        } catch {
            logger?.log(error, message: "😡 Decode response")
            lastMessageResponse = nil
            lastMessageHashValue = 0
        }
        
        return nil
    }
}

// MARK: - Rx

extension ObservableType where E == WebSocket.Connection {
    typealias ConnectionStatusHandler = (_ connected: Bool) -> Void
    
    func connected(_ connectionStatusHandler: ConnectionStatusHandler? = nil) -> Observable<Void> {
        return self.do(onNext: { connectionStatusHandler?($0.isConnected) })
            .filter { $0.isConnected }
            .map { _ in }
    }
}
