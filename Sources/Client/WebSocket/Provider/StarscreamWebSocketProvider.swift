//
//  StarscreamWebSocketProvider.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 30/04/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import Starscream

final class StarscreamWebSocketProvider: WebSocketProvider {
    private let webSocket: Starscream.WebSocket
    var request: URLRequest { webSocket.request }
    var isConnected: Bool { webSocket.isConnected }
    var callbackQueue: DispatchQueue { webSocket.callbackQueue }
    weak var delegate: WebSocketProviderDelegate?
    
    init(request: URLRequest, callbackQueue: DispatchQueue?) {
        webSocket = Starscream.WebSocket(request: request)
        webSocket.delegate = self
        
        if let callbackQueue = callbackQueue {
            webSocket.callbackQueue = callbackQueue
        }
    }
    
    func connect() {
        webSocket.connect()
    }
    
    func disconnect() {
        webSocket.disconnect(forceTimeout: 0)
    }
    
    func sendPing() {
        webSocket.write(ping: .empty)
    }
}

extension StarscreamWebSocketProvider: Starscream.WebSocketDelegate {
    
    func websocketDidConnect(socket: Starscream.WebSocketClient) {
        delegate?.websocketDidConnect(self)
    }
    
    func websocketDidDisconnect(socket: Starscream.WebSocketClient, error: Error?) {
        var webSocketProviderError: WebSocketProviderError?
        
        if let error = error {
            if let starscreamError = error as? WSError {
                webSocketProviderError = .init(error: error, code: starscreamError.code)
            } else {
                webSocketProviderError = .init(error: error, code: 0)
            }
        }
        
        delegate?.websocketDidDisconnect(self, error: webSocketProviderError)
    }
    
    func websocketDidReceiveMessage(socket: Starscream.WebSocketClient, text: String) {
        delegate?.websocketDidReceiveMessage(self, text: text)
    }
    
    func websocketDidReceiveData(socket: Starscream.WebSocketClient, data: Data) {}
}
