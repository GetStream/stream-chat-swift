//
//  TestCase.swift
//  StreamChatCoreTests
//
//  Created by Alexey Bukhtin on 22/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

class TestCase: XCTestCase {
    
    var connectByDefault: Bool {
        return true
    }
    
    static let apiKey = "qk4nn7rpcn75"
    private static var isClientReady = false
    private(set) lazy var defaultChannel = Channel(type: .messaging, id: "general")
    
    static func setupClientUser() {
        Client.shared.set(user: .user1, token: .token1)
    }
    
    override static func setUp() {
        if isClientReady {
            return
        }
        
        isClientReady = true
        WebSocket.pingTimeInterval = 3
        ClientLogger.logger = { print($0, $1.isEmpty ? "" : "[\($1)]", $2) }
        Client.config = .init(apiKey: TestCase.apiKey, logOptions: .info)
    }
    
    override func setUp() {
        if connectByDefault, !Client.shared.isConnected {
            TestCase.setupClientUser()
            Client.shared.connect()
        }
    }
    
    override static func tearDown() {
        Client.shared.disconnect()
    }
    
    func test00Connected() {
        guard connectByDefault else {
            return
        }
        
        expect("Client should be connected") { expectation in
            if Client.shared.isConnected {
                expectation.fulfill()
                return
            }
            
            Client.shared.onConnect = {
                if case .connected = $0 {
                    expectation.fulfill()
                }
            }
        }
    }
    
    func expect(_ description: String = "",
                timeout: TimeInterval = TimeInterval(5),
                callback: (_ test: XCTestExpectation) -> Void) {
        let test = expectation(description: "⏳ expecting \(description)")
        callback(test)
        wait(for: [test], timeout: timeout)
    }
}
