//
//  Channel+KeystrokeTests.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 29/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class Channel_KeystrokeTests: ClientTestCase {
    
    var time: VirtualTime!
    let maxStopTypingTimeInterval: VirtualTime.Seconds = 15
    let maxEesendTimeInterval: VirtualTime.Seconds = 20
    
    override func setUp() {
        super.setUp()
        time = VirtualTime()
        VirtualTimeTimer.time = time
    }
    
    func test_channel_keystroke() throws {
        let channel = client.channel(type: .messaging, id: "test-keystroke")
        
        // 1. The first keystroke.
        sendKeystroke(in: channel)
        
        // Assert
        AssertNetworkRequest(
            method: .post,
            path: "/channels/messaging/test-keystroke/event",
            headers: ["Content-Type": "application/json"],
            queryParameters: ["api_key": "test_api_key"],
            body: ["event": ["type": "typing.start"]]
        )
        
        time.run(numberOfSeconds: 5)
        
        // 2. The second keystroke, the request should be skipped.
        // Reset stop typing timer.
        sendKeystroke(in: channel)
        
        if RequestRecorderURLProtocol.waitForRequest(timeout: 1) != nil {
            XCTFail("The second request for the keystroke should be skipped inside time interval 2")
            return
        }
        
//        time.run(numberOfSeconds: 1)
//
//        // 3. The fourth keystroke, the request shouldn't be skipped. User is typing too long.
//        sendKeystroke(in: channel)
//
//        // Assert
//        AssertNetworkRequest(
//            method: .post,
//            path: "/channels/messaging/test-keystroke/event",
//            headers: ["Content-Type": "application/json"],
//            queryParameters: ["api_key": "test_api_key"],
//            body: ["event": ["type": "typing.start"]]
//        )
        
        // 4. The stop typing event should be called after timeout 2.
        time.run(numberOfSeconds: maxStopTypingTimeInterval + 1)
        
        // Assert
        AssertNetworkRequest(
            method: .post,
            path: "/channels/messaging/test-keystroke/event",
            headers: ["Content-Type": "application/json"],
            queryParameters: ["api_key": "test_api_key"],
            body: ["event": ["type": "typing.stop"]]
        )
    }
    
    private func sendKeystroke(in channel: Channel) {
        channel.keystroke(client: client, timerType: VirtualTimeTimer.self) { _ in }
    }
    
    func test_channel_stopTyping() throws {
        let channel = client.channel(type: .messaging, id: "test-stop-typing")
        channel.stopTyping(client: client) { _ in }
        
        if RequestRecorderURLProtocol.waitForRequest(timeout: 1) != nil {
            XCTFail("The stop typing event shouldn't be send if keystroke wasn't send")
            return
        }
        
        sendKeystroke(in: channel)
        
        AssertNetworkRequest(
            method: .post,
            path: "/channels/messaging/test-stop-typing/event",
            headers: ["Content-Type": "application/json"],
            queryParameters: ["api_key": "test_api_key"],
            body: ["event": ["type": "typing.start"]]
        )
        
        channel.stopTyping(client: client) { _ in }

        AssertNetworkRequest(
            method: .post,
            path: "/channels/messaging/test-stop-typing/event",
            headers: ["Content-Type": "application/json"],
            queryParameters: ["api_key": "test_api_key"],
            body: ["event": ["type": "typing.stop"]]
        )
        
        channel.stopTyping(client: client) { _ in }
        
        if RequestRecorderURLProtocol.waitForRequest(timeout: 1) != nil {
            XCTFail("The stop typing event shouldn't be send if keystroke wasn't send")
            return
        }
    }
}
