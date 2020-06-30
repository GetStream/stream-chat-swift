//
// StarscreamWebSocketEngine.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

#if canImport(Starscream)
    import Starscream
    
    final class StarscreamWebSocketProvider: WebSocketEngine {
        private let webSocket: Starscream.WebSocket
        var request: URLRequest { webSocket.request }
        var isConnected: Bool { webSocket.isConnected }
        var callbackQueue: DispatchQueue { webSocket.callbackQueue }
        weak var delegate: WebSocketEngineDelegate?
        
        init(request: URLRequest, sessionConfiguration: URLSessionConfiguration, callbackQueue: DispatchQueue) {
            // Starscream doesn't support taking session configuration as a parameter se we need to copy
            // the headers manually.
            let requestHeaders = request.allHTTPHeaderFields ?? [:]
            let sessionHeaders = sessionConfiguration.httpAdditionalHeaders as? [String: String] ?? [:]
            
            let allHeaders = requestHeaders.merging(sessionHeaders, uniquingKeysWith: { fromRequest, _ in
                // In case of duplicity, use the request header value
                fromRequest
            })
            
            var request = request
            request.allHTTPHeaderFields = allHeaders
            
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
            webSocket.write(ping: Data([]))
        }
    }
    
    extension StarscreamWebSocketProvider: Starscream.WebSocketDelegate {
        func websocketDidConnect(socket: Starscream.WebSocketClient) {
            delegate?.websocketDidConnect()
        }
        
        func websocketDidDisconnect(socket: Starscream.WebSocketClient, error: Error?) {
            var engineError: WebSocketEngineError?
            
            if let error = error {
                engineError = .init(reason: error.localizedDescription,
                                    code: (error as? WSError)?.code ?? 0,
                                    engineError: error)
            }
            
            delegate?.websocketDidDisconnect(error: engineError)
        }
        
        func websocketDidReceiveMessage(socket: Starscream.WebSocketClient, text: String) {
            delegate?.websocketDidReceiveMessage(text)
        }
        
        func websocketDidReceiveData(socket: Starscream.WebSocketClient, data: Data) {}
    }
    
#endif
