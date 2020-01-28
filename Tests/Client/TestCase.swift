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
    
    static let apiKey = "qk4nn7rpcn75"
    static let baseURL = BaseURL(serverLocation: .staging)
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
        ClientLogger.logger = { print($0, $2) }
        
        Client.config = .init(apiKey: Self.apiKey,
                              baseURL: Self.baseURL,
                              callbackQueue: .main,
                              stayConnectedInBackground: false,
                              logOptions: .webSocketInfo)
    }
    
    override static func tearDown() {
        Client.shared.disconnect()
        Client.shared.onConnect = { _ in }
        Client.shared.onEvent = { _ in }
        StorageHelper.shared.removeAll()
    }
}

extension TestCase {
    
    func expectConnection() {
        if Client.shared.isConnected {
            return
        }
        
        TestCase.setupClientUser()
        Client.shared.connect()
        
        expect("Client should be connected") { expectation in
            Client.shared.onConnect = {
                if case .connected = $0 {
                    expectation.fulfill()
                }
            }
        }
    }
    
    func connect(_ client: Client, user: User = .user1, token: Token = .token1, _ completion: @escaping () -> Void) {
        var connected = false
        
        func finish() {
            if !connected {
                connected = true
                completion()
            }
        }
        
        client.set(user: user, token: token)
        
        if client.isConnected {
            finish()
            return
        }
        
        client.onConnect = {
            if case .connected = $0 {
                finish()
            }
        }
        
        client.connect()
    }
    
    func expect(_ description: String,
                timeout: TimeInterval = TimeInterval(5),
                callback: (_ test: XCTestExpectation) -> Void) {
        let test = expectation(description: "\n💥💀✝️ expecting \(description)")
        callback(test)
        wait(for: [test], timeout: timeout)
    }
}

final class StorageHelper {
    
    enum StorageKey: String {
        case client1
        case client2
        case notificationAddedToChannel
        case notificationMessageNew
    }
    
    static let shared = StorageHelper()
    private var storage = [StorageKey: Any]()
    
    func add<T>(_ value: T, key: StorageKey) {
        storage[key] = value
    }
    
    func value<T>(key: StorageKey, default: T? = nil) -> T? {
        return (storage[key] as? T) ?? `default`
    }
    
    func increment(key: StorageKey) {
        if let value = value(key: key, default: 0) {
            storage[key] = value + 1
        }
    }
    
    fileprivate func removeAll() {
        storage.removeAll()
    }
}
