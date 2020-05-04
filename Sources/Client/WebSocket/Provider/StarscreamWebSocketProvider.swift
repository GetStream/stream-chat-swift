//
//  StarscreamWebSocketProvider.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 30/04/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

// For customers who will use only iOS 13+ no need to add Starscream framework.
#if canImport(Starscream)
import Starscream

final class StarscreamWebSocketProvider: WebSocketProvider {
    private let webSocket: Starscream.WebSocket
    var request: URLRequest { webSocket.request }
    var isConnected: Bool { webSocket.isConnected }
    var callbackQueue: DispatchQueue { webSocket.callbackQueue }
    weak var delegate: WebSocketProviderDelegate?
    
    init(request: URLRequest, callbackQueue: DispatchQueue) {
        webSocket = Starscream.WebSocket(request: request)
        webSocket.delegate = self
        webSocket.callbackQueue = callbackQueue
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
            webSocketProviderError = .init(reason: error.localizedDescription,
                                           code: (error as? WSError)?.code ?? 0,
                                           providerType: StarscreamWebSocketProvider.self,
                                           providerError: error)
        }
        
        delegate?.websocketDidDisconnect(self, error: webSocketProviderError)
    }
    
    func websocketDidReceiveMessage(socket: Starscream.WebSocketClient, text: String) {
        delegate?.websocketDidReceiveMessage(self, message: text)
    }
    
    func websocketDidReceiveData(socket: Starscream.WebSocketClient, data: Data) {}
}

#endif
