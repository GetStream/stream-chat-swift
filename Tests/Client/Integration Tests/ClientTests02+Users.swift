//
//  Client03+Users.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 19/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class ClientTests02_Users: TestCase {
    
    func test00Users() {
        expectConnection()
        
        expect("users list") { expectation in
            let filter = Filter.equal("id", to: User.current.id) & .equal("name", to: User.current.name)
            Client.shared.queryUsers(filter: filter) {
                if let users = $0.value {
                    XCTAssertEqual(users.first!, User.current)
                    expectation.fulfill()
                }
            }
        }
    }
    
    func test01UserUpdate() {
        expectConnection()
        
        let oldUserName = Client.shared.user.name
        let newUserName = "NewUserName"
        
        var user = Client.shared.user
        
        expect("User name update") { (expectation) in
            // Update user name
            user.name = newUserName
            Client.shared.update(user: user) { (result) in
                do {
                    _ = try result.get()
                    
                    XCTAssertEqual(Client.shared.user.name, newUserName)
                    XCTAssertEqual(User.current.name, newUserName)
                    
                    expectation.fulfill()
                } catch {
                    XCTFail("Error when updating user: \(error)")
                }
            }
        }
        
        expect("Restore user name") { (expectation) in
            // Restore user name
            user.name = oldUserName
            Client.shared.update(user: user) { (result) in
                do {
                    _ = try result.get()
                    
                    XCTAssertEqual(Client.shared.user.name, oldUserName)
                    XCTAssertEqual(User.current.name, oldUserName)
                    
                    expectation.fulfill()
                } catch {
                    XCTFail("Error when restoring user: \(error)")
                }
            }
        }
    }
}
