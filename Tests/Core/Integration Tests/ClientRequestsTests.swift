//
//  StreamChatCoreTests.swift
//  StreamChatCoreTests
//
//  Created by Alexey Bukhtin on 21/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import XCTest
import RxSwift
import RxBlocking
@testable import StreamChatCore

final class ClientRequestsTests: TestCase {
    
    func testChannelsQuery() {
        do {
            let query = ChannelsQuery(filter: "type".equal(to: "messaging"))
            
            let channels = try Client.shared.rx.channels(query: query)
                .toBlocking()
                .toArray()
                .compactMap { $0 }
            
            XCTAssertTrue(!channels.isEmpty)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testUsersQuery() {
        do {
            let query = UsersQuery(filter: "id".equal(to: User.user1.id))
            
            let users = try Client.shared.rx.users(query: query)
                .toBlocking()
                .toArray()
                .compactMap { $0 }
            
            XCTAssertEqual(users.count, 1)
        } catch {
            XCTFail("\(error)")
        }
    }
}

