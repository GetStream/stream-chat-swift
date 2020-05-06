//
//  WebSocketProviderProxy.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 06/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

final class WebSocketProviderProxy: WebSocketProvider {
    private var provider: WebSocketProvider
    
    var request: URLRequest { provider.request }
    var isConnected: Bool { provider.isConnected }
    var callbackQueue: DispatchQueue { provider.callbackQueue }
    
    var delegate: WebSocketProviderDelegate? {
        get { return provider.delegate }
        set { provider.delegate = newValue }
    }
    
    init(request: URLRequest, callbackQueue: DispatchQueue) {
        if #available(iOS 13, *) {
            provider = URLSessionWebSocketProvider(request: request, callbackQueue: callbackQueue)
        } else {
            provider = StarscreamWebSocketProvider(request: request, callbackQueue: callbackQueue)
        }
    }
    
    func connect() {
        provider.connect()
    }
    
    func disconnect() {
        provider.disconnect()
    }
    
    func sendPing() {
        provider.sendPing()
    }
}
