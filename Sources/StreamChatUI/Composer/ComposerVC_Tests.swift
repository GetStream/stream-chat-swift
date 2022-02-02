//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import XCTest

class ComposerVC_Tests: XCTestCase {
    func testSearchByIDOrName() throws {
        let user1 = ChatUser.mock(id: "searchingThis")
        let user2 = ChatUser.mock(id: "x", name: "searchingThis")

        XCTAssertEqual(searchUsers([user1], by: "sear"), [user1])
        XCTAssertEqual(searchUsers([user2], by: "sear"), [user2])
    }

    func testMatchConsistentTieBreaker() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "Tommaso")
        let thierry = ChatUser.mock(id: "thierry", name: "Thierry")
        let users = [tommaso, thierry]

        XCTAssertEqual(searchUsers(users, by: ""), [thierry, tommaso])
        XCTAssertEqual(searchUsers(users, by: ""), [thierry, tommaso])
        XCTAssertEqual(searchUsers(users, by: ""), [thierry, tommaso])
        XCTAssertEqual(searchUsers(users, by: ""), [thierry, tommaso])
        XCTAssertEqual(searchUsers(users, by: ""), [thierry, tommaso])
        XCTAssertEqual(searchUsers(users, by: ""), [thierry, tommaso])
        XCTAssertEqual(searchUsers(users, by: ""), [thierry, tommaso])
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

    func testMatchHappySortedByDistancePrefix() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "tommaso")
        let tommasi = ChatUser.mock(id: "tommasi", name: "tommasi")
        let users = [tommaso, tommasi]

        XCTAssertEqual(searchUsers(users, by: "t"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "to"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tom"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tomm"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tomma"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tommas"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tommaso"), [tommaso])
    }

    func testMatchHappySortedByDistancePrefix2() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "tommaso")
        let tommasi = ChatUser.mock(id: "tommasi", name: "tommasi")
        let users = [tommasi, tommaso]

        XCTAssertEqual(searchUsers(users, by: "t"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "to"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tom"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tomm"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tomma"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tommas"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tommaso"), [tommaso])
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
    
    func test_attachmentsPreview_withFourAttachments_addedSameTime() {
        let composerVC = ComposerVC()
        composerVC.appearance = Appearance.default
        
        composerVC.content = .initial()
        composerVC.content.attachments = [.mockFile, .mockFile, .mockFile, .mockFile]
        
        AssertSnapshot(composerVC)
    }
    
    func test_attachmentsPreview_withFourAttachments_addedOneAfterThree() {
        let composerVC = ComposerVC()
        composerVC.appearance = Appearance.default
        
        composerVC.content = .initial()
        composerVC.content.attachments = [.mockFile, .mockFile, .mockFile]
        
        composerVC.content.attachments.append(.mockFile)
        
        AssertSnapshot(composerVC)
    }
    
    func test_attachmentsPreview_withFourAttachments_addedTwoAfterTwo() {
        let composerVC = ComposerVC()
        composerVC.appearance = Appearance.default
        
        composerVC.content = .initial()
        composerVC.content.attachments = [.mockFile, .mockFile]
        
        composerVC.content.attachments.append(contentsOf: [.mockFile, .mockFile])
        
        AssertSnapshot(composerVC)
    }
    
    func test_attachmentsPreview_withFourAttachments_addedThreeAfterOne() {
        let composerVC = ComposerVC()
        composerVC.appearance = Appearance.default
        
        composerVC.content = .initial()
        composerVC.content.attachments = [.mockFile]
        
        composerVC.content.attachments.append(contentsOf: [.mockFile, .mockFile, .mockFile])
        
        AssertSnapshot(composerVC)
    }
}
