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

final class ClientSetupTests: XCTestCase {
    
    var disposeBag = DisposeBag()
    
    override static func setUp() {
        DateFormatter.log = nil
        Client.config = .init(apiKey: TestCase.apiKey, logOptions: [.webSocketInfo, .requests])
    }
    
    func testUserSetup() {
        setupUser(user: User.user1, token: .token1) {
            XCTAssertEqual(Client.shared.user, User.user1)
            XCTAssertEqual(Client.shared.token, .token1)
        }
    }
    
    func testGuestSetup() {
        setupUser(user: User.user1, token: .guest) {
            XCTAssertEqual(Client.shared.user?.role, .guest)
            XCTAssertNotNil(Client.shared.token)
        }
    }
    
    func testDevelopmentSetup() {
        /// Disconnected by error:
        /// Error(code: 5, message: "development tokens are not allowed for this application", statusCode: 401)
        //        setupUser(token: .development) { [unowned self] in
        //            XCTAssertEqual(self.setupClient.user, .user2)
        //            XCTAssertNotNil(self.setupClient.token)
        //        }
    }

    func setupUser(user: User, token: Token, asserts: @escaping () -> Void) {
        Client.shared.set(user: user, token: token)
        
        expectRequest("Connected with guest token") { test in
            Client.shared.connection.connected()
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
