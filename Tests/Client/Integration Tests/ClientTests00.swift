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
    
    func test01WebSocketConnection() {
        expect("WebSocket connected") { expectation in
            TestCase.setupClientUser()
            
            Client.shared.onConnect = { connection in
                if case .connected = connection {
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
    
    func test02AnonymousUser() {
        expect("WebSocket connected") { expectation in
            Client.shared.setAnonymousUser()
            
            Client.shared.onConnect = { connection in
                if case .connected = connection {
                    XCTAssertTrue(Client.shared.isConnected)
                    Client.shared.onConnect = { _ in }
                    expectation.fulfill()
                }
            }
            
            Client.shared.connect()
        }
        
        expect("create a channel for anonymous") { expectation in
            Client.shared.create(channel: Channel(type: .messaging, id: "anon")) {
                if let clientError = $0.error,
                    case .responseError(let responseError) = clientError,
                    responseError.code == 17 {
                    expectation.fulfill()
                }
            }
        }
        
        expect("channels for anonymous") { expectation in
            Client.shared.queryChannels {
                if $0.isSuccess {
                    Client.shared.disconnect()
                    expectation.fulfill()
                }
            }
        }
    }
    
    func test03WebSocketPong() {
        expect("WebSocket recieved a pong") { expectation in
            WebSocket.pingTimeInterval = 2
            TestCase.setupClientUser()
            
            Client.shared.onEvent = { event in
                if case .pong = event {
                    Client.shared.disconnect()
                    Client.shared.onEvent = { _ in }
                    WebSocket.pingTimeInterval = 30
                    expectation.fulfill()
                }
            }
            
            Client.shared.connect()
        }
    }
}
