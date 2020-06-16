//
// WebSocketEngine_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatClient_v3

class WebSocketEngineMock: WebSocketEngine {
    var request: URLRequest
    var isConnected: Bool = false
    var callbackQueue: DispatchQueue
    weak var delegate: WebSocketEngineDelegate?
    
    /// How many times was `connect()` called
    var connect_calledCount = 0
    
    /// How many times was `disconnect()` called
    var disconnect_calledCount = 0
    
    /// How many times was `sendPing()` called
    var sendPing_calledCount = 0
    
    convenience init() {
        self.init(request: .init(url: URL(string: "test_url")!), callbackQueue: .main)
    }
    
    required init(request: URLRequest, callbackQueue: DispatchQueue) {
        self.request = request
        self.callbackQueue = callbackQueue
    }
    
    func connect() {
        connect_calledCount += 1
    }
    
    func disconnect() {
        disconnect_calledCount += 1
    }
    
    func sendPing() {
        sendPing_calledCount += 1
    }
    
    // MARK: - Functions to simulate behavior
    
    func simulateConnectionSuccess() {
        isConnected = true
        delegate?.websocketDidConnect()
    }
    
    func simulateMessageReceived(_ json: [String: Any] = [:]) {
        let data = try! JSONSerialization.data(withJSONObject: json, options: [])
        simulateMessageReceived(data)
    }
    
    func simulateMessageReceived(_ data: Data) {
        delegate?.websocketDidReceiveMessage(String(data: data, encoding: .utf8)!)
    }
    
    func simulateDisconnect(_ error: WebSocketEngineError? = nil) {
        isConnected = false
        delegate?.websocketDidDisconnect(error: error)
    }
}
