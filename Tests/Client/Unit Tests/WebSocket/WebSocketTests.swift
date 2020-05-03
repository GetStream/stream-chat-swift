//
//  WebSocketTests.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 02/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class WebSocketTests: XCTestCase {
    
    let mockProvider = WebSocketProviderMock(request: URLRequest(url: URL(string: "http://test.com")!))
    let logger = ClientLogger(icon: "🦄", level: .info)
    
    override static func setUp() {
        WebSocket.pingTimeInterval = 2
    }
    
    override class func tearDown() {
        WebSocket.pingTimeInterval = 25
    }
    
    func test_webSocket_connectWithSubscription() {
        // Wait for connected event from 2 subscriptions.
        let connectedExpectation = expectation(description: "WebSocket connected")
        connectedExpectation.expectedFulfillmentCount = 2
        
        // On force disconnect the WebSocket shouldn't try to reconnect.
        let shouldntReconnectExpectation = expectation(description: "WebSocket shouldn't reconnect")
        shouldntReconnectExpectation.isInverted = true
        
        let eventsHandler: Client.OnEvent = { event in
            guard case .connectionChanged(let state) = event else {
                return
            }
            
            if case .connected = state {
                connectedExpectation.fulfill()
            } else if case .reconnecting = state {
                shouldntReconnectExpectation.fulfill()
            }
        }
        
        let webSocket = WebSocket(mockProvider, options: .stayConnectedInBackground, onEvent: eventsHandler)
        _ = webSocket.subscribe(callback: eventsHandler)
        
        XCTAssertFalse(webSocket.isConnected)
        webSocket.connect()
        wait(for: [connectedExpectation], timeout: 2)
        XCTAssertTrue(webSocket.isConnected)
        webSocket.disconnect(reason: "test")
        XCTAssertFalse(webSocket.isConnected)
        wait(for: [shouldntReconnectExpectation], timeout: 1)
    }
    
    func test_webSocket_reconnection() {
        // Expect 3 connected events. 2 from reconnection.
        let connectedExpectation = expectation(description: "WebSocket connected twice")
        connectedExpectation.expectedFulfillmentCount = 3
        let reconnectingExpectation = expectation(description: "WebSocket reconnecting")
        reconnectingExpectation.expectedFulfillmentCount = 2
        
        let webSocket = WebSocket(mockProvider, options: .stayConnectedInBackground) { event in
            guard case .connectionChanged(let state) = event else {
                return
            }
            
            if case .connected = state {
                connectedExpectation.fulfill()
                self.mockProvider.disconnect()
            } else if case .reconnecting = state {
                reconnectingExpectation.fulfill()
            }
        }
        
        webSocket.connect()
        wait(for: [connectedExpectation, reconnectingExpectation], timeout: 2)
    }
    
    func test_webSocket_reconnect3times() {
        // Expect connected event after 3 attempts.
        let connectedExpectation = expectation(description: "WebSocket connected twice")
        let reconnectingExpectation = expectation(description: "WebSocket reconnecting")
        reconnectingExpectation.expectedFulfillmentCount = 3
        let shouldntConnectExpectation = expectation(description: "WebSocket shouldn't connect after 2 sec")
        shouldntConnectExpectation.isInverted = true

        let webSocket = WebSocket(mockProvider, options: .stayConnectedInBackground) { event in
            guard case .connectionChanged(let state) = event else {
                return
            }
            
            if case .connected = state {
                connectedExpectation.fulfill()
                shouldntConnectExpectation.fulfill()
            } else if case .reconnecting = state {
                reconnectingExpectation.fulfill()
            }
        }
        
        mockProvider.failNextConnectCount = 3
        webSocket.connect()
        wait(for: [shouldntConnectExpectation], timeout: 2)
        wait(for: [connectedExpectation, reconnectingExpectation], timeout: 10)
    }
    
    func test_webSocket_ping() {
        // Keep Connection for 4 sec.
        let shouldntDisconnectWithStopErrorExpectation = expectation(description: "WebSocket shouldn't recieve stop error")
        shouldntDisconnectWithStopErrorExpectation.isInverted = true
        
        let webSocket = WebSocket(mockProvider, options: .stayConnectedInBackground) { event in
            if case .connectionChanged(let state) = event,
                case .disconnected(let clientError) = state,
                case .websocketDisconnectError(let websocketDisconnectError) = clientError,
                let webSocketProviderError = websocketDisconnectError as? WebSocketProviderError,
                webSocketProviderError.code == WebSocketProviderError.stopErrorCode {
                shouldntDisconnectWithStopErrorExpectation.fulfill()
            }
        }
        
        webSocket.connect()
        wait(for: [shouldntDisconnectWithStopErrorExpectation], timeout: 4)
        XCTAssertTrue(webSocket.isConnected)
    }
}
