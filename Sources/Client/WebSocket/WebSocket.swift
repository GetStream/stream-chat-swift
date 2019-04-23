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
//    private static let maxAttemptsToReconnect = 5

    private let logger: ClientLogger?
    private let webSocket: Starscream.WebSocket
    private let disposeBag = DisposeBag()
//    private var weakChannels = [WeakChannel]()
//    private var attemptsToReconnect: Int = 0
//    private var clientId: String?
//
    private lazy var handshakeTimer = RepeatingTimer(timeInterval: .seconds(30), queue: webSocket.callbackQueue) { [weak self] in
        self?.logger?.log("🏓", "🆙")
        self?.webSocket.write(ping: Data())
    }
    
    public var isConnected: Bool {
        return webSocket.isConnected
    }
    
    /// Create a Faye client with a given `URL`.
    ///
    /// - Parameters:
    ///     - url: an `URL` of your websocket server.
    ///     - headers: custom headers.
    public init(_ urlRequest: URLRequest, logger: ClientLogger? = nil) {
        self.logger = logger
        webSocket = Starscream.WebSocket(request: urlRequest)
        webSocket.callbackQueue = DispatchQueue(label: "io.getstream.Chat", qos: .userInitiated)
        logger?.log(urlRequest)
        
        webSocket.rx.response
            .subscribe(onNext: { [weak self] in self?.parse($0) },
                       onError: { [weak self] in self?.logger?.log($0) })
            .disposed(by: disposeBag)
    }
    
    func connect() {
        if webSocket.isConnected {
           webSocket.disconnect()
        }
        
        DispatchQueue.main.async(execute: webSocket.connect)
    }
    
    func disconnect() {
        if webSocket.isConnected {
            webSocket.disconnect()
        }
    }

    private func parse(_ response: WebSocketEvent) {
        switch response {
        case .connected:
            logger?.log("Connected")
            handshakeTimer.resume()
            
        case .disconnected(let error):
            logger?.log("Disconnected")
            handshakeTimer.suspend()
            
            if let error = error {
                logger?.log(error, message: "Disconnected")
            }
        case .message(let msg):
            logger?.log("📄", msg)
        case .data(let data):
            logger?.log("Data", data.debugDescription)
        case .pong:
            logger?.log("🏓","🆗")
        }
    }
    
    deinit {
        disconnect()
    }
}

//// MARK: - Channel

//extension Client {
//
//    public func subscribe(to channel: Channel) throws {
//        if !weakChannels.contains(where: { $0.channel == channel }) {
//            weakChannels.append(WeakChannel(channel))
//        }
//
//        guard isConnected else {
//            throw Error.notConnected
//        }
//        
//        try webSocketWrite(.subscribe, channel)
//    }
//    
//    func unsubscribe(channel: Channel) throws {
//        guard isConnected else {
//            return
//        }
//
//        try webSocketWrite(.unsubscribe, channel)
//    }
//
//    func remove(channel: Channel) {
//        weakChannels = weakChannels.filter { $0.channel != channel }
//        try? unsubscribe(channel: channel)
//    }
//}
//
//// MARK: - Connection
//
//extension Client: WebSocketDelegate {
//
//    public func websocketDidConnect(socket: WebSocketClient) {
//        do {
//            try webSocketWrite(.handshake)
//            attemptsToReconnect = 0
//            handshakeTimer.resume()
//        } catch {
//            log("❌", error)
//            applyAdvice()
//        }
//    }
//
//    public func websocketDidDisconnect(socket: WebSocketClient, error: Swift.Error?) {
//        log()
//        handshakeTimer.suspend()
//        clientId = nil
//        
//        if let error = error {
//            log("❌", error)
//        }
//
//        applyAdvice()
//    }
//    
//    private func retryReconnect(after timeInterval: DispatchTimeInterval = .seconds(2)) {
//        guard attemptsToReconnect < Client.maxAttemptsToReconnect else {
//            attemptsToReconnect = 0
//            return
//        }
//
//        log()
//        webSocket.callbackQueue.asyncAfter(deadline: .now() + timeInterval) { [weak self] in self?.connect() }
//    }
//}
//
//// MARK: - Sending
//
//extension Client {
//    private func webSocketWrite(_ bayeuxChannel: BayeuxChannel,
//                                _ channel: Channel? = nil,
//                                completion: ClientWriteDataCompletion? = nil) throws {
//        guard webSocket.isConnected else {
//            throw Error.notConnected
//        }
//        
//        guard clientId != nil || bayeuxChannel == BayeuxChannel.handshake else {
//            throw Error.clientIdIsEmpty
//        }
//        
//        let message = Message(bayeuxChannel, channel, clientId: self.clientId)
//        let data = try JSONEncoder().encode([message])
//        webSocket.write(data: data, completion: completion)
//        log("--->", message.channel, message.clientId ?? "", message.ext ?? [:])
//    }
//}
//
//// MARK: - Receiving
//
//extension Client {
//    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
//        guard let data = text.data(using: .utf8) else {
//            log("❌", "Bad data encoding")
//            return
//        }
//        
//        log("<---", text)
//        websocketDidReceiveData(socket: socket, data: data)
//    }
//
//    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
//        do {
//            guard let json = try JSONSerialization.jsonObject(with: data) as? [JSON] else {
//                return
//            }
//
//            let messages = try JSONDecoder().decode([Message].self, from: data)
//            
//            messages.forEach { message in
//                if !dispatchBayeuxChannel(with: message) {
//                    json.forEach {
//                        if let subscriptionJSON = $0["data"] as? JSON,
//                            let jsonData = try? JSONSerialization.data(withJSONObject: subscriptionJSON) {
//                            dispatchData(with: message, in: jsonData)
//                        }
//                    }
//                }
//            }
//        } catch {
//            log("❌", error)
//        }
//    }
//    
//    private func dispatchBayeuxChannel(with message: Message) -> Bool {
//        guard let bayeuxChannel = BayeuxChannel(rawValue: message.channel) else {
//            return false
//        }
//
//        if case .handshake = bayeuxChannel {
//            dispatchHandshake(with: message)
//        }
//
//        return true
//    }
//    
//    private func dispatchData(with message: Message, in jsonData: Data) {
//        log("<---", message.channel)
//
//        weakChannels.forEach { weakChannel in
//            if let channel = weakChannel.channel, channel.name.match(with: message.channel) {
//                channel.subscription(jsonData)
//            }
//        }
//    }
//    
//    private func dispatchHandshake(with message: Message) {
//        clientId = message.clientId
//        advice = message.advice
//
//        for weakChannel in weakChannels {
//            if let channel = weakChannel.channel {
//                do {
//                    try subscribe(to: channel)
//                } catch {
//                    log("❌ subscribe to channel", channel, error)
//                    break
//                }
//            }
//        }
//    }
//}

//// MARK: - Advice
//
//extension WebSocket {
//    private func applyAdvice() {
//        clientId = nil
//
//        guard let advice = advice else {
//            retryReconnect()
//            return
//        }
//
//        log("<-->", advice)
//
//        switch advice.reconnect {
//        case .none:
//            return
//        case .handshake:
//            try? webSocketWrite(.handshake)
//        case .retry:
//            retryReconnect()
//        }
//        
//        self.advice = nil
//    }
//}
//
//// MARK: - Error
//
//extension WebSocket {
//    public enum Error: String, Swift.Error {
//        case notConnected
//        case clientIdIsEmpty
//    }
//}
//
//// MARK: - Helpers
//
//private final class WeakChannel {
//    weak var channel: Channel?
//    
//    init(_ channel: Channel) {
//        self.channel = channel
//    }
//}
