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
    
    var emittedEvents: [Event]!
    
    let logger = ClientLogger(icon: "🦄", level: .info)
    
    override func setUp() {
        super.setUp()
        
        emittedEvents = []
        
        time = VirtualTime()
        VirtualTimeTimer.time = time
        
        socketProvider = WebSocketProviderMock()
        webSocket = WebSocket(socketProvider,
                              options: [],
                              timerType: VirtualTimeTimer.self,
                              onEvent: { self.emittedEvents.append($0) })
        
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
}

private extension Dictionary {
    
    /// Helper function to create a `health.check` event JSON with the given `userId` and `connectId`.
    static func healthCheckEvent(userId: String, connectionId: String) -> [String: Any] {
        [
            "created_at" : "2020-05-02T13:21:03.862065063Z",
            "me" : [
                "id" : userId,
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
            ],
            "type" : "health.check",
            "connection_id" : connectionId
        ]
    }
}
