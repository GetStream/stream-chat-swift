//
//  Client.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 15/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

class ClientTests: TestCase {

    func testConnection() {
        expect("WebSocket connection") { expectation in
            TestCase.setupClientUser()
            Client.shared.webSocket.onConnect = { connection in
                if case .connected(let connectionId, _) = connection {
                    XCTAssertTrue(!connectionId.isEmpty)
                    XCTAssertTrue(Client.shared.webSocket.isConnected)
                    Client.shared.disconnect()
                    XCTAssertFalse(Client.shared.webSocket.isConnected)
                    expectation.fulfill()
                }
            }

            Client.shared.webSocket.connect()
        }
    }
    
    func testPong() {
        expect("WebSocket waiting for pong", timeout: 40) { expectation in
            TestCase.setupClientUser()
            
            Client.shared.webSocket.onEvent = { event in
                if case .pong = event {
                    expectation.fulfill()
                }
            }
            
            Client.shared.webSocket.connect()
        }
    }
}
