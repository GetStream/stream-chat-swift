//
//  Client03+Users.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 19/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class Client03_Users: TestCase {
    
    func test01Users() {
        expect("users list") { expectation in
            let filter = "id".equal(to: User.current.id) + "name".equal(to: User.current.name)
            Client.shared.queryUsers(.init(filter: filter)) {
                if let users = $0.value {
                    XCTAssertEqual(users.first!, User.current)
                    expectation.fulfill()
                }
            }
        }
    }
}
