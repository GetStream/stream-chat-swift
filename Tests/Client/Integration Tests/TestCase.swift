//
//  TestCase.swift
//  StreamChatCoreTests
//
//  Created by Alexey Bukhtin on 22/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

let defaultTimeout = 10

class TestCase: XCTestCase {
    
    static let apiKey = "qk4nn7rpcn75"
    static let baseURL = BaseURL(url: URL(string: "https://chat-us-east-staging.stream-io-api.com/")!)
    private static var isClientReady = false
    static let subscriptionBag = SubscriptionBag()
    
    static func setupClientUser() {
        Client.shared.set(user: .user2, token: .token2)
    }
    
    override static func setUp() {
        if isClientReady {
            return
        }
        
        isClientReady = true
        ClientLogger.log = { icon, date, level, message in print(icon, message) }
        
        Client.configureShared(.init(
            apiKey: Self.apiKey,
            baseURL: Self.baseURL,
            stayConnectedInBackground: false,
            callbackQueue: .main,
            logOptions: []
        ))
    }
    
    override static func tearDown() {
        Client.shared.disconnect()
        subscriptionBag.cancel()
        StorageHelper.shared.removeAll()
    }
}

extension TestCase {
    
    func expectConnection() {
        if Client.shared.isConnected {
            return
        }
        
        TestCase.setupClientUser()
        
        expect("Client should be connected") { expectation in
            TestCase.subscriptionBag.add(Client.shared.subscribe(forEvents: [.connectionChanged], {
                if case .connectionChanged(let connectionState) = $0, connectionState.isConnected {
                    expectation.fulfill()
                }
            }))
        }
    }
    
    func connect(_ client: Client, user: User = .user1, token: Token = .token1, _ completion: @escaping () -> Void) {
        if client.isConnected {
            completion()
            return
        }
        
        client.set(user: user, token: token) { result in
            if result.isSuccess {
                completion()
            }
        }
    }
    
    func expect(_ description: String,
                timeout: TimeInterval = TimeInterval(defaultTimeout),
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
        case user2UnreadCounts
        case deleteChannels
        case deleteMessages
    }
    
    static let shared = StorageHelper()
    private var storage = [StorageKey: Any]()
    
    func add<T>(_ value: T, key: StorageKey) {
        storage[key] = value
    }
    
    func append<T>(_ value: T, key: StorageKey) {
        guard let storedValues = storage[key, default: [T]()] as? [T] else {
            return
        }
        
        var values = storedValues
        values.append(value)
        storage[key] = values
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
