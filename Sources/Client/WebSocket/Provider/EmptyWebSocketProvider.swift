//
//  EmptyWebSocketProvider.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 30/04/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

final class EmptyWebSocketProvider: WebSocketProvider {
    let request: URLRequest
    let isConnected = false
    let callbackQueue: DispatchQueue
    weak var delegate: WebSocketProviderDelegate?
    
    init(request: URLRequest, callbackQueue: DispatchQueue?) {
        self.request = request
        self.callbackQueue = callbackQueue ?? .global()
    }
    
    func connect() {}
    func disconnect() {}
    func sendPing() {}
}
