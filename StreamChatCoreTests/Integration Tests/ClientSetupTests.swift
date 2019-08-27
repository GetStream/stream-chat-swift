//
//  ClientSetupTests.swift
//  StreamChatCoreTests
//
//  Created by Alexey Bukhtin on 26/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import XCTest
import RxSwift
@testable import StreamChatCore

final class ClientSetupTests: TestCase {
    
    private var setupClient = Client(apiKey: TestCase.apiKey, logOptions: .all)
    
    func testUserSetup() {
        // Test regular user.
        setupUser(token: .token2) { [unowned self] in
            XCTAssertEqual(self.setupClient.user, User.user2)
            XCTAssertEqual(self.setupClient.token, .token2)
        }
        
        // Test guest.
        setupUser(token: .guest) { [unowned self] in
            XCTAssertEqual(self.setupClient.user?.role, .guest)
            XCTAssertNotNil(self.setupClient.token)
        }
        
        // Test development user.
        /// Disconnected by error:
        /// Error(code: 5, message: "development tokens are not allowed for this application", statusCode: 401)
//        setupUser(token: .development) { [unowned self] in
//            XCTAssertEqual(self.setupClient.user, .user2)
//            XCTAssertNotNil(self.setupClient.token)
//        }
    }
    
    func setupUser(token: Token, asserts: @escaping () -> Void) {
        setupClient.set(user: User.user2, token: token)
        
        expectRequest("Connected with guest token") { test in
            setupClient.connection.connected()
                .take(1)
                .subscribe(onNext: { [unowned self] in
                    test.fulfill()
                    asserts()
                    self.disposeBag = DisposeBag()
                })
                .disposed(by: disposeBag)
        }
    }
}
