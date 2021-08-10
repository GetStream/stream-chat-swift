//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import SwiftUI
import XCTest

class ComposerVC_Tests: XCTestCase {
    func testSearchByIDOrName() throws {
        let user1 = ChatUser.mock(id: "searchingThis")
        let user2 = ChatUser.mock(id: "x", name: "searchingThis")

        XCTAssertEqual(searchUsers([user1], by: "sear"), [user1])
        XCTAssertEqual(searchUsers([user2], by: "sear"), [user2])
    }

    func testMatchHappy() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "Tommaso")
        let thierry = ChatUser.mock(id: "thierry", name: "Thierry")
        let users = [tommaso, thierry]

        XCTAssertEqual(searchUsers(users, by: "tom"), [tommaso])
        XCTAssertEqual(searchUsers(users, by: "thier"), [thierry])
    }

    func testMatchHappyLowercased() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "Tommaso")
        let thierry = ChatUser.mock(id: "thierry", name: "Thierry")
        let users = [tommaso, thierry]

        XCTAssertEqual(searchUsers(users, by: "Tom"), [tommaso])
        XCTAssertEqual(searchUsers(users, by: "Thier"), [thierry])
    }

    func testMatchHappyTranslitterated() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "Tommaso")
        let thierry = ChatUser.mock(id: "thierry", name: "Thierry")
        let users = [tommaso, thierry]

        XCTAssertEqual(searchUsers(users, by: "tóm"), [tommaso])
        XCTAssertEqual(searchUsers(users, by: "thíer"), [thierry])
    }

    func testMatchHappySortedByDistance() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "tommaso")
        let tomas = ChatUser.mock(id: "tomas", name: "tomas")
        let users = [tommaso, tomas]

        XCTAssertEqual(searchUsers(users, by: "tom"), [tomas, tommaso])
    }

    func testMatchHappyCyrillic() throws {
        let petyo = ChatUser.mock(id: "42", name: "Петьо")
        let anastasia = ChatUser.mock(id: "13", name: "Анастасiя")
        let dmitriy = ChatUser.mock(id: "99", name: "Дмитрий")
        let users = [petyo, anastasia, dmitriy]

        XCTAssertEqual(searchUsers(users, by: "petyo"), [])
        XCTAssertEqual(searchUsers(users, by: "Пе"), [petyo])
        XCTAssertEqual(searchUsers(users, by: "Ана"), [anastasia])
        XCTAssertEqual(searchUsers(users, by: "Дмитрии"), [dmitriy])
        XCTAssertEqual(searchUsers(users, by: "Дмитри"), [dmitriy])
    }

    func testMatchHappyFrench() throws {
        let user = ChatUser.mock(id: "fra", name: "françois")

        XCTAssertEqual(searchUsers([user], by: "françois"), [user])
        XCTAssertEqual(searchUsers([user], by: "franc"), [user])
    }
}
