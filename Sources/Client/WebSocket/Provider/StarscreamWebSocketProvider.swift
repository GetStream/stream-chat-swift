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
    
    var request: URLRequest {
        get { webSocket.request }
        set {
            disconnect()
            webSocket.request = newValue
        }
    }
    
    private(set) var isConnected = false
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
        webSocket.disconnect()
    }
    
    func sendPing() {
        webSocket.write(ping: .empty)
    }
}

extension StarscreamWebSocketProvider: Starscream.WebSocketDelegate {
    
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocket) {
        switch event {
        case .connected:
            didConnect()
        case let .text(text):
            delegate?.websocketDidReceiveMessage(text)
        case let .error(error):
            didDisconnect(error: error.flatMap {
                .init(reason: $0.localizedDescription,
                      code: Int(($0 as? WSError)?.code ?? 0),
                      providerType: StarscreamWebSocketProvider.self,
                      providerError: $0)
            })
        case let .disconnected(reason, code):
            didDisconnect(error: .init(reason: reason,
                                       code: Int(code),
                                       providerType: StarscreamWebSocketProvider.self,
                                       providerError: nil))
        case .cancelled:
            didDisconnect(error: .init(reason: "Cancelled",
                                       code: -1,
                                       providerType: StarscreamWebSocketProvider.self,
                                       providerError: nil))
        default:
            break
        }
    }
    
    private func didConnect() {
        isConnected = true
        delegate?.websocketDidConnect()
    }
    
    private func didDisconnect(error: WebSocketProviderError?) {
        isConnected = false
        delegate?.websocketDidDisconnect(error: error)
    }
    
}
