//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ComposerVC_Tests: XCTestCase {
    func test_userFound_whenSearchedByIDOrName() throws {
        let user1 = ChatUser.mock(id: "searchingThis")
        let user2 = ChatUser.mock(id: "x", name: "searchingThis")

        XCTAssertEqual(searchUsers([user1], by: "sear"), [user1])
        XCTAssertEqual(searchUsers([user2], by: "sear"), [user2])
    }

    func test_usersFound_whenSearchedWithTieBreaker() throws {
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

    func test_userFound_whenTypingTheBeginningOfIDOrName() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "Tommaso")
        let thierry = ChatUser.mock(id: "thierry", name: "Thierry")
        let users = [tommaso, thierry]

        XCTAssertEqual(searchUsers(users, by: "tom"), [tommaso])
        XCTAssertEqual(searchUsers(users, by: "thier"), [thierry])
    }

    func test_userFound_whenStartOfTheNameMatchesCase() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "Tommaso")
        let thierry = ChatUser.mock(id: "thierry", name: "Thierry")
        let users = [tommaso, thierry]

        XCTAssertEqual(searchUsers(users, by: "Tom"), [tommaso])
        XCTAssertEqual(searchUsers(users, by: "Thier"), [thierry])
    }

    func test_userFound_whenNameIsTranslitterated() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "Tommaso")
        let thierry = ChatUser.mock(id: "thierry", name: "Thierry")
        let users = [tommaso, thierry]

        XCTAssertEqual(searchUsers(users, by: "tóm"), [tommaso])
        XCTAssertEqual(searchUsers(users, by: "thíer"), [thierry])
    }

    func test_usersFoundAndSroted_whenSearchedByBeginningOfNameOrID() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "tommaso")
        let tomas = ChatUser.mock(id: "tomas", name: "tomas")
        let users = [tommaso, tomas]

        XCTAssertEqual(searchUsers(users, by: "tom"), [tomas, tommaso])
    }

    func test_userFound_whenHappySortedByDistancePrefix() throws {
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

    func test_userFound_whenHappySortedByDistancePrefix2() throws {
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

    func test_userFound_whenHappyCyrillic() throws {
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

    func test_userFound_whenHappyFrench() throws {
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

    func test_attachmentsPreview_withMultipleAttachmentTypes() {
        let composerVC = ComposerVC()
        composerVC.appearance = Appearance.default

        composerVC.content = .initial()
        composerVC.content.attachments = [.mockFile, .mockFile, .mockImage, .mockVideo]

        AssertSnapshot(composerVC)
    }

    func test_attachmentsPreview_withLongFileNames() {
        let composerVC = ComposerVC()
        composerVC.appearance = Appearance.default

        composerVC.content = .initial()
        composerVC.content.attachments = [.mockFileWithLongName]

        AssertSnapshot(composerVC, variants: [.defaultLight])
    }
    
    func test_commandWithNonEmptyArgs_hasSendButtonDisabled() {
        let composerVC = ComposerVC()
        composerVC.appearance = Appearance.default
        
        composerVC.content = .initial()
        composerVC.content.addCommand(.init(
            name: "ARGNEEDED",
            description: "some command",
            set: "special",
            args: "[text]"
        ))
        
        AssertSnapshot(composerVC)
    }
    
    func test_commandWithEmptyArgs_hasSendButtonEnabled() {
        let composerVC = ComposerVC()
        composerVC.appearance = Appearance.default
        
        composerVC.content = .initial()
        composerVC.content.addCommand(.init(
            name: "NOARGNEEDED",
            description: "some command",
            set: "special",
            args: ""
        ))
        
        AssertSnapshot(composerVC)
    }
    
    func test_whenSuggestionsLookupIsLocal_onlyChannelMembersAreShown() {
        final class ComposerContainerVC: UIViewController {
            var composerVC: ComposerVC!
            var textWithMention = ""
            
            override func viewDidLoad() {
                super.viewDidLoad()
                
                view.backgroundColor = .white
                addChildViewController(composerVC, targetView: view)
                composerVC.view.pin(anchors: [.leading, .trailing, .bottom], to: view)
            }

            override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                
                composerVC.content.text = textWithMention
            }
        }
        
        let member: ChatChannelMember = .mock(
            id: "1",
            name: "Yoda (member)",
            imageURL: nil
        )
        
        let watcher: ChatUser = .mock(
            id: "2",
            name: "Yoda (watcher)",
            imageURL: nil
        )
        
        let mockUserSearchController = ChatUserSearchController_Mock.mock()
        
        let mockChannelController = ChatChannelController_Mock.mock()
        mockChannelController.client.currentUserId = .unique
        mockChannelController.channel_mock = .mock(
            cid: .unique,
            lastActiveMembers: [member],
            lastActiveWatchers: [watcher]
        )
        
        let composerVC = ComposerVC()
        composerVC.userSearchController = mockUserSearchController
        composerVC.channelController = mockChannelController
        
        let containerVC = ComposerContainerVC()
        containerVC.composerVC = composerVC
        containerVC.textWithMention = "@Yo"
        
        AssertSnapshot(containerVC, variants: [.defaultLight])
    }
}
