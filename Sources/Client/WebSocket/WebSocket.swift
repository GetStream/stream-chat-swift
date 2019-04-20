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
        self?.logger?.log("🏓", "--->")
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
            logger?.log("🏓","<---")
        }
    }
    
    deinit {
        disconnect()
    }
}
