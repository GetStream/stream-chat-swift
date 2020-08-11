//
//  WebSocketTests.swift
//  StreamChatClientTests
//
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class WebSocketTests: XCTestCase {
    
    // The longest time WebSocket waits to reconnect. This is hardcoded in WebSocket.
    let maxReconnectTimeout: VirtualTime.Seconds = 25
    
    var time: VirtualTime!
    
    var socketProvider: WebSocketProviderMock!
    var webSocket: WebSocket!
    var connectionId: String!
    var user: User!
    
    let logger = ClientLogger(icon: "🦄", level: .info)
    
    override func setUp() {
        super.setUp()
        
        time = VirtualTime()
        VirtualTimeTimer.time = time
        
        socketProvider = WebSocketProviderMock()
        webSocket = WebSocket(socketProvider,
                              options: [],
                              timerType: VirtualTimeTimer.self)
        
        connectionId = UUID().uuidString
        user = User(id: "test_user_\(UUID().uuidString)")
    }
    
    func test_connectionFlow() {
        webSocket.connect()
        AssertAsync.willBeEqual(self.socketProvider.connectCalledCount, 1)
        XCTAssertFalse(webSocket.isConnected)
        
        socketProvider.simulateConnectionSuccess()
        socketProvider.simulateMessageReceived(.healthCheckEvent(userId: user.id, connectionId: connectionId))
        
        AssertAsync.willBeEqual(self.webSocket.isConnected, true)
        XCTAssertEqual(webSocket.connectionId, connectionId)
    }
    
    func test_reconnectionFlow_withoutStopError() {
        // Setup (connect)
        test_connectionFlow()
        let originalConnectCalledCount = socketProvider.connectCalledCount
        
        // Action (disconnect 10 times)
        for _ in 0..<10 {
            socketProvider.simulateDisconnect()
            time.run(numberOfSeconds: maxReconnectTimeout + 1)
        }
        
        XCTAssertEqual(socketProvider.connectCalledCount, originalConnectCalledCount + 10)
    }

    func test_reconnectionFlow_withStopError_shouldntReconnect() {
        // Setup (connect)
        test_connectionFlow()
                        
        let stopError = WebSocketProviderError(reason: "test",
                                               code: WebSocketProviderError.stopErrorCode,
                                               providerType: WebSocketProviderMock.self,
                                               providerError: nil)
        
        let originalConnectCalledCount = socketProvider.connectCalledCount

        // Action
        socketProvider.simulateDisconnect(stopError)
        time.run(numberOfSeconds: maxReconnectTimeout + 1)
        
        // Assert
        AssertAsync {
            Assert.staysTrue(self.socketProvider.connectCalledCount == originalConnectCalledCount)
        }
    }

    func test_reconnectionFlow_whenDisconnectedManually_shouldntReconnect() {
        // Setup (connect)
        test_connectionFlow()
        let originalConnectCalledCount = socketProvider.connectCalledCount

        // Action
        webSocket.disconnect(reason: "Tests")
        time.run(numberOfSeconds: maxReconnectTimeout + 1)
        
        // Assert
        AssertAsync {
            Assert.staysTrue(self.socketProvider.connectCalledCount == originalConnectCalledCount)
        }
    }

    func test_pingIsSentPeriodically() {
        // Setup (connect)
        test_connectionFlow()
        
        let pingInterval = WebSocket.pingTimeInterval
        assert(socketProvider.sendPingCalledCounter == 0)
        
        // Action
        time.run(numberOfSeconds: pingInterval + 1)
        XCTAssertEqual(socketProvider.sendPingCalledCounter, 1)
        
        time.run(numberOfSeconds: 3 * pingInterval)
        XCTAssertEqual(socketProvider.sendPingCalledCounter, 1 + 3)
    }
    
    func test_typingEvent_stopTyping_afterTimeout() {
        // Setup (connect)
        test_connectionFlow()
        
        // Set `shouldAutomaticallySendTypingStopEvent` to `true`
        let delegate = MockDelegate()
        delegate.shouldAutomaticallySendTypingStopEvent = true
        webSocket.eventDelegate = delegate
        
        // Simulate some user started typing
        let otherUser = User(id: UUID().uuidString)
        socketProvider.simulateMessageReceived(.typingStartEvent(userId: otherUser.id))
        
        var nextEvent: Event?
        _ = webSocket.subscribe { nextEvent = $0 }

        // Wait for the timeout and expect a `typingStop` event.
        time.run(numberOfSeconds: WebSocket.incomingTypingStartEventTimeout + 1)
        AssertAsync.willBeEqual(nextEvent, .typingStop(otherUser, nil, .typingStop))
    }
    
    func test_typingEvent_stopTyping_notSentWhenDelegateReturnsFalse() {
        // Setup (connect)
        test_connectionFlow()

        // Set `shouldAutomaticallySendTypingStopEvent` to `false`
        let delegate = MockDelegate()
        delegate.shouldAutomaticallySendTypingStopEvent = false
        webSocket.eventDelegate = delegate

        // Simulate a user started typing
        socketProvider.simulateMessageReceived(.typingStartEvent(userId: user.id))
        
        var nextEvent: Event?
        _ = webSocket.subscribe { nextEvent = $0 }

        // Wait for the timeout and expect no `typingStop` event.
        time.run(numberOfSeconds: WebSocket.incomingTypingStartEventTimeout + 1)
        AssertAsync.staysTrue(nextEvent != .typingStop(user, nil, .typingStop))
    }
}

private class MockDelegate: WebSocketEventDelegate {
    var shouldPublishEvent: Bool = true
    var shouldAutomaticallySendTypingStopEvent: Bool = true
    
    func shouldPublishEvent(_ event: Event) -> Bool { shouldPublishEvent }
    func shouldAutomaticallySendTypingStopEvent(for user: User) -> Bool { shouldAutomaticallySendTypingStopEvent }
}
