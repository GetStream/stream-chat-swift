//
//  Client+RxEventsTests.swift
//  StreamChatCoreTests
//
//  Created by Alexey Bukhtin on 03/06/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
import RxSwift
import RxBlocking
@testable import StreamChatClient
@testable import StreamChatCore

final class Client_RxEventsTests: ClientTestCase {
    
    override static func setUp() {
        super.setUp()
        _ = sharedClient
    }
    
    func test_client_rxConnectionState() throws {
        let webSocketProvider = client.webSocket.provider as! WebSocketProviderMock
        
        DispatchQueue.main.async {
            webSocketProvider.simulateConnectionSuccess()
            webSocketProvider.simulateMessageReceived(.healthCheckEvent(userId: self.testUser.id, connectionId: self.testSessionId))
            self.client.disconnect()
            self.client.set(user: self.testUser, token: self.testToken)
            webSocketProvider.simulateConnectionSuccess()
            webSocketProvider.simulateMessageReceived(.healthCheckEvent(userId: self.testUser.id, connectionId: self.testSessionId))
        }
        
        let events = try client.rx.connectionState
            .take(7)
            .toBlocking(timeout: 5)
            .toArray()
            .compactMap { $0 }
        
        let healthCheckData: [String: Any] = .healthCheckEvent(userId: testUser.id, connectionId: testSessionId)
        let userData = try! JSONSerialization.data(withJSONObject: healthCheckData["me"] as Any)
        let user = try! JSONDecoder.stream.decode(User.self, from: userData)
        let userConnection = UserConnection(user: user, connectionId: testSessionId)
        
        XCTAssertEqual(events, [.disconnected(nil),
                                .connecting,
                                .connected(userConnection),
                                .disconnecting,
                                .disconnected(nil),
                                .connecting,
                                .connected(userConnection)])
    }
}
