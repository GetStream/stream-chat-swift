//
//  ClientTests00.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 15/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class ClientTests00: TestCase {
    
    override var connectByDefault: Bool {
        return false
    }
    
    func test00WebSocketConnection() {
        expect("WebSocket connected") { expectation in
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
    
    func test01WebSocketPong() {
        expect("WebSocket recieved a pong") { expectation in
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
