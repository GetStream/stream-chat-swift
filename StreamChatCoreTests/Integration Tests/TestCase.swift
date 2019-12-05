//
//  TestCase.swift
//  StreamChatCoreTests
//
//  Created by Alexey Bukhtin on 22/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import XCTest
import RxSwift
@testable import StreamChatCore

class TestCase: XCTestCase {
    
    static let apiKey = "qk4nn7rpcn75"
    private static var isClientReady = false
    
    var disposeBag = DisposeBag()
    
    override static func setUp() {
        if isClientReady {
            return
        }
        
        isClientReady = true
        ClientLogger.logger = { print($0, $1.isEmpty ? "" : "[\($1)]", $2) }
        Client.config = .init(apiKey: TestCase.apiKey, logOptions: .info)
        Client.shared.set(user: .user1, token: .token1)
    }
    
    override func setUp() {
        if !Client.shared.webSocket.isConnected {
            Client.shared.connection.connected().subscribe().disposed(by: disposeBag)
        }
    }
}

extension XCTestCase {
    
    func expectRequest(_ description: String, callback: (_ test: XCTestExpectation) -> Void) {
        expect(description, timeout: 5, callback: callback)
    }
    
    func expect(_ description: String, timeout: TimeInterval = TimeInterval(1), callback: (_ test: XCTestExpectation) -> Void) {
        let test = expectation(description: "⏳ expecting \(description)")
        callback(test)
        wait(for: [test], timeout: timeout)
    }
}
