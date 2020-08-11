//
//  WebSocketProviderMock.swift
//  StreamChatClientTests
//
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class WebSocketProviderMock: WebSocketProvider {
    var request: URLRequest
    
    var isConnected: Bool = false
    
    var callbackQueue: DispatchQueue
    
    var delegate: WebSocketProviderDelegate?

    /// How many times was `connect()` called
    var connectCalledCount = 0

    /// How many times was `sendPing()` called
    var sendPingCalledCounter = 0

    convenience init() {
        self.init(request: .init(url: .placeholder), callbackQueue: .main)
    }
    
    required init(request: URLRequest, callbackQueue: DispatchQueue) {
        self.request = request
        self.callbackQueue = callbackQueue
    }
    
    func connect() {
        connectCalledCount += 1
    }
    
    func disconnect() {
        isConnected = false
        delegate?.websocketDidDisconnect(error: nil)
    }
    
    func sendPing() {
        sendPingCalledCounter += 1
    }

    // MARK: - Functions to simulate behavior

    func simulateConnectionSuccess() {
        isConnected = true
        delegate?.websocketDidConnect()
    }
    
    func simulateMessageReceived(_ json: [String: Any]) {
        let data = try! JSONSerialization.data(withJSONObject: json, options: [])
        delegate?.websocketDidReceiveMessage(String(data: data, encoding: .utf8)!)
    }
    
    func simulateDisconnect(_ error: WebSocketProviderError? = nil) {
        isConnected = false
        delegate?.websocketDidDisconnect(error: error)
    }
}
