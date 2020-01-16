//
//  ClientTests.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 15/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class ClientTests: TestCase {

    func testConnection() {
        expect("WebSocket connection") { expectation in
            TestCase.setupClientUser()
            
            Client.shared.onConnect = { connection in
                if case .connected(let connectionId, _) = connection {
                    XCTAssertTrue(!connectionId.isEmpty)
                    XCTAssertTrue(Client.shared.isConnected)
                    Client.shared.disconnect()
                    XCTAssertFalse(Client.shared.isConnected)
                    Client.shared.onConnect = { _ in }
                    expectation.fulfill()
                }
            }
            
            Client.shared.connect()
        }
    }
    
    func testPong() {
        expect("WebSocket waiting for pong") { expectation in
            TestCase.setupClientUser()
            
            Client.shared.onEvent = { event in
                if case .pong = event {
                    Client.shared.disconnect()
                    Client.shared.onEvent = { _ in }
                    expectation.fulfill()
                }
            }
            
            Client.shared.connect()
        }
    }
}
