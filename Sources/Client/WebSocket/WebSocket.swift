//
//  WebSocket.swift
//  GetStreamChat
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
    
    let webSocket: Starscream.WebSocket
    private(set) lazy var reachability = Reachability()
    private(set) var lastError: Error?
    private(set) var lastConnectionId: String?
    private(set) var consecutiveFailures: TimeInterval = 0
    let logger: ClientLogger?
    var isReconnecting = false
    
    private var lastMessageHashValue: Int = 0
    private var lastMessageResponse: Response?
    
    private lazy var handshakeTimer = RepeatingTimer(timeInterval: .seconds(30), queue: webSocket.callbackQueue) { [weak self] in
        self?.logger?.log("🏓")
        self?.webSocket.write(ping: Data())
    }
    
    private(set) lazy var connection: Observable<WebSocket.Connection> = {
        let app = UIApplication.shared
        let connection = reachability?.connection ?? .none
        let reachabilityObservation = reachability?.rx.reachabilityChanged.map { $0.connection }.startWith(connection) ?? .empty()
        
        return Observable.combineLatest(app.rx.appState.startWith(app.appState),
                                        reachabilityObservation,
                                        webSocket.rx.response)
            .do(onSubscribed: { [weak self] in self?.reconnect() },
                onDispose: { [weak self] in self?.disconnect() })
            .map { [weak self] in self?.parseConnection(appState: $0, reachability: $1, event: $2) }
            .unwrap()
            .distinctUntilChanged()
            .share(replay: 1)
    }()
    
    private(set) lazy var response: Observable<WebSocket.Response> = Observable
        .combineLatest(webSocket.rx.response, connection.connected())
        .map { [weak self] event, _ in self?.parseMessage(event) }
        .unwrap()
        .share(replay: 1)
    
    init(_ urlRequest: URLRequest, logger: ClientLogger? = nil) {
        self.logger = logger
        webSocket = Starscream.WebSocket(request: urlRequest)
        webSocket.callbackQueue = DispatchQueue(label: "io.getstream.Chat", qos: .userInitiated)
        
        if let host = urlRequest.url?.host {
            reachability = Reachability(hostname: host)!
            startReachability()
        }
    }
    
    deinit {
        reachability?.stopNotifier()
        disconnect()
    }
    
    private func startReachability() {
        do {
            try reachability?.startNotifier()
        } catch {
            logger?.log(error, message: "😡 Reachability")
        }
    }
    
    func connect() {
        if webSocket.isConnected || isReconnecting {
           return
        }
        
        logger?.log("❤️", "Connecting...")
        logger?.log(webSocket.request)
        startReachability()
        DispatchQueue.main.async(execute: webSocket.connect)
    }
    
    func disconnect() {
        lastConnectionId = nil
        
        if webSocket.isConnected {
            logger?.log("💔", "Disconnecting...")
            handshakeTimer.suspend()
            webSocket.disconnect()
            reachability?.stopNotifier()
        }
    }
}

// MARK: - Parsing

extension WebSocket {
    
    private func parseConnection(appState: AppState, reachability: Reachability.Connection, event: WebSocketEvent) -> Connection? {
        guard reachability != .none else {
            lastConnectionId = nil
            return .notConnected
        }
        
        if appState == .background {
            disconnect()
            return .notConnected
        }
        
        if case .message = event {
            if let response = parseMessage(event),
                case let .healthCheck(connectionId, healthCheckUser) = response.event,
                let user = healthCheckUser {
                lastConnectionId = connectionId
                return .connected(connectionId, user)
            } else if lastError != nil {
                return nil
            }
        }
        
        if appState == .active, !webSocket.isConnected, lastError == nil {
            reconnect()
            return .connecting
        }
        
        switch event {
        case .connected:
            logger?.log("😊 Connected")
            handshakeTimer.resume()
            return .connecting
            
        case .disconnected(let error):
            logger?.log("🤔 Disconnected")
            handshakeTimer.suspend()
            
            if let error = error {
                logger?.log(error, message: "😡 Disconnected")
            }
            
            let parsedError = parseDisconnect(error)
            
            if parsedError == nil {
                consecutiveFailures += 1
            } else {
                consecutiveFailures = 0
            }
            
            return .notConnected //.disconnected(parsedError)
            
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
        lastError = nil
        
        if let errorContsainer = try? JSONDecoder.stream.decode(ErrorContainer.self, from: data) {
            lastError = errorContsainer.error
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
    typealias DoConnected = (_ connected: Bool) -> Void
    
    func connected(_ doConnected: DoConnected? = nil) -> Observable<E> {
        return filter {
            doConnected?($0.isConnected)
            return $0.isConnected
        }
    }
}
