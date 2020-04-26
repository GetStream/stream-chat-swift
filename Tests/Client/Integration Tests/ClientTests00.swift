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
            
            var subscription: Cancellable?
            subscription = Client.shared.subscribe(forEvents: [.connectionChanged]) {
                if case .connectionChanged(let connectionState) = $0, connectionState.isConnected {
                    XCTAssertTrue(Client.shared.isConnected)
                    Client.shared.disconnect()
                    XCTAssertFalse(Client.shared.isConnected)
                    subscription?.cancel()
                    expectation.fulfill()
                }
            }
        }
    }
    
    func test02AnonymousUser() {
        expect("WebSocket connected") { expectation in
            Client.shared.setAnonymousUser()
            
            var subscription: Cancellable?
            subscription = Client.shared.subscribe(forEvents: [.connectionChanged]) {
                if case .connectionChanged(let connectionState) = $0, connectionState.isConnected {
                    XCTAssertTrue(Client.shared.isConnected)
                    subscription?.cancel()
                    expectation.fulfill()
                }
            }
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
            Client.shared.queryChannels(filter: .currentUserInMembers) {
                if $0.isSuccess {
                    Client.shared.disconnect()
                    expectation.fulfill()
                }
            }
        }
    }
}
