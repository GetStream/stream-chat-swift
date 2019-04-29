//
//  WebSocket.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 18/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import Starscream
import RxSwift
import RxStarscream

final class WebSocket {
    
    private let logger: ClientLogger?
    private let webSocket: Starscream.WebSocket
    
    private lazy var handshakeTimer = RepeatingTimer(timeInterval: .seconds(30), queue: webSocket.callbackQueue) { [weak self] in
        self?.logger?.log("🏓")
        self?.webSocket.write(ping: Data())
    }
    
    private(set) lazy var connection: Observable<WebSocket.Connection> = webSocket.rx.response
        .startWith(.pong)
        .filter { [weak self] in
            if case .pong = $0 {
                self?.connect()
                return false
            }
            
            return true
        }
        .map { [weak self] in self?.parseConnection($0) }
        .unwrap()
        .distinctUntilChanged()
        .share(replay: 1, scope: .forever)
    
    private(set) lazy var response: Observable<WebSocket.Response> =
        Observable.combineLatest(connection.connected(), webSocket.rx.response)
            .map { [weak self] _, event in self?.parseResponse(event) }
            .unwrap()
            .share(replay: 1, scope: .whileConnected)
    
    init(_ urlRequest: URLRequest, logger: ClientLogger? = nil) {
        self.logger = logger
        webSocket = Starscream.WebSocket(request: urlRequest)
        webSocket.callbackQueue = DispatchQueue(label: "io.getstream.Chat", qos: .userInitiated)
    }
    
    deinit {
        disconnect()
    }
    
    func connect() {
        if webSocket.isConnected {
           webSocket.disconnect()
        }
        
        logger?.log(webSocket.request)
        DispatchQueue.main.async(execute: webSocket.connect)
    }
    
    func disconnect() {
        if webSocket.isConnected {
            webSocket.disconnect()
        }
    }
}

// MARK: - Parsing

extension WebSocket {
    
    private func parseConnection(_ event: WebSocketEvent) -> Connection? {
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
            
            reconnect()
            
            return .disconnected(error)
            
        case .message:
            if let response = parseResponse(event),
                case let .healthCheck(connectionId, healthCheckUser) = response.event,
                let user = healthCheckUser {
                return .connected(connectionId, user)
            }
            
        default:
            break
        }
        
        return nil
    }
    
    private func reconnect() {
        webSocket.callbackQueue.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.connect()
        }
    }
    
    private func parseResponse(_ event: WebSocketEvent) -> Response? {
        guard case .message(let message) = event else {
            return nil
        }
        
        guard let data = message.data(using: .utf8) else {
            logger?.log("📦", "Can't get a data from the message: \(message)")
            return nil
        }
        
        logger?.log("📦", data)
        
        do {
            return try JSONDecoder.stream.decode(Response.self, from: data)
        } catch {
            logger?.log(error, message: "😡 Decode response")
        }
        
        return nil
    }
}

// MARK: - Rx

extension ObservableType where E == WebSocket.Connection {
    func connected() -> Observable<E> {
        return filter {
            if case .connected = $0 {
                return true
            }
            
            return false
        }
    }
}
