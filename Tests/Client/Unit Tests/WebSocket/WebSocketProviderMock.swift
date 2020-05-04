//
//  WebSocketProviderMock.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 01/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class WebSocketProviderMock: WebSocketProvider {
    let request: URLRequest
    var isConnected: Bool = false
    let callbackQueue: DispatchQueue
    weak var delegate: WebSocketProviderDelegate?
    private var connectionId: String?
    
    var failNextConnectCount = 0
    let timeout = 3
    private var timer: DispatchSourceTimer?
    
    init(request: URLRequest, callbackQueue: DispatchQueue) {
        self.request = request
        self.callbackQueue = callbackQueue
    }
    
    func connect() {
        if failNextConnectCount > 0 {
            failNextConnectCount -= 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                self.delegate?.websocketDidDisconnect(self, error: nil)
            }
            
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.isConnected = true
            self.startTimer()
            self.delegate?.websocketDidConnect(self)
            
            // Send the first event with the current user.
            let event = """
                {
                "created_at" : "2020-05-02T13:21:03.862065063Z",
                "me" : {
                "id" : "steep-moon-9",
                "banned" : false,
                "unread_channels" : 0,
                "mutes" : [],
                "last_active" : "2020-05-02T13:21:03.849219Z",
                "created_at" : "2019-06-05T15:01:52.847807Z",
                "devices" : [],
                "invisible" : false,
                "unread_count" : 0,
                "channel_mutes" : [],
                "image" : "https://i.imgur.com/EgEPqWZ.jpg",
                "updated_at" : "2020-05-02T13:21:03.855468Z",
                "role" : "user",
                "total_unread_count" : 0,
                "online" : true,
                "name" : "steep-moon-9",
                "test" : 1
                },
                "type" : "health.check",
                "connection_id" : "
                """
            
            self.connectionId = UUID().uuidString
            self.sendMessage(event + self.connectionId! + #"", "cid" : "*"}"#)
        }
    }
    
    func disconnect() {
        disconnect(error: nil)
    }
    
    func disconnect(error: WebSocketProviderError?) {
        isConnected = false
        connectionId = nil
        stopTimer()
        delegate?.websocketDidDisconnect(self, error: error)
    }
    
    func sendPing() {
        guard let connectionId = connectionId else {
            return
        }
        
        let event = "{\"type\":\"health.check\",\"connection_id\":\""
            + connectionId
            + "\",\"cid\":\"*\",\"created_at\":\"2020-05-01T14:45:35.844826426Z\"}"
        
        sendMessage(event)
        startTimer()
    }
    
    func sendMessage(_ message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.delegate?.websocketDidReceiveMessage(self, message: message)
        }
    }
    
    func sendStop() {
        isConnected = false
        connectionId = nil
        stopTimer()
        let error = WebSocketProviderError(reason: "stop", code: 1000, providerType: Self.self, providerError: nil)
        delegate?.websocketDidDisconnect(self, error: error)
    }
    
    func startTimer() {
        stopTimer()
        timer = DispatchSource.makeTimerSource(queue: .main)
        timer?.schedule(deadline: .now() + .seconds(timeout))
        timer?.setEventHandler(handler: sendStop)
        timer?.resume()
    }
    
    func stopTimer() {
        timer?.setEventHandler {}
        timer?.cancel()
    }
}
