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
            Client.shared.onConnect = { connection in
                if case .connected = connection {
                    XCTAssertTrue(Client.shared.isConnected)
                    Client.shared.disconnect()
                    XCTAssertFalse(Client.shared.isConnected)
                    Client.shared.onConnect = { _ in }
                    expectation.fulfill()
                }
            }
            
            TestCase.setupClientUser()
        }
    }
    
    func test02AnonymousUser() {
        expect("WebSocket connected") { expectation in
            Client.shared.onConnect = { connection in
                if case .connected = connection {
                    XCTAssertTrue(Client.shared.isConnected)
                    Client.shared.onConnect = { _ in }
                    expectation.fulfill()
                }
            }
            
            Client.shared.setAnonymousUser()
        }
        
        expect("create a channel for anonymous") { expectation in
            Client.shared.channel(type: .messaging, id: "anon").create {
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
}
