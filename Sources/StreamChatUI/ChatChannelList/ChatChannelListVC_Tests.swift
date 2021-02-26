//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatChannelListVC_Tests: XCTestCase {
    var view: ChatChannelListItemView!
    var vc: ChatChannelListVC!
    var mockedChannelListController: ChatChannelListController_Mock<NoExtraData>!
    var mockedCurrentUserController: CurrentChatUserController_Mock<NoExtraData>!
    var mockedRouter: ChatChannelListRouter_Mock<NoExtraData> { vc.router as! ChatChannelListRouter_Mock<NoExtraData> }
    
    // Workaround for setting mockedCurrentUserController to userAvatarView.
    class TestChatChannelListVC: ChatChannelListVC {
        var mockedCurrentUserController: CurrentChatUserController_Mock<NoExtraData>?
        
        override func setUp() {
            super.setUp()
            
            userAvatarView.controller = mockedCurrentUserController
        }
    }
    
    override func setUp() {
        super.setUp()
        mockedChannelListController = ChatChannelListController_Mock.mock()
        mockedCurrentUserController = CurrentChatUserController_Mock.mock()
        mockedCurrentUserController.currentUser_mock = .init(
            id: "Yoda",
            imageURL: TestImages.yoda.url
        )
        
        let testVC = TestChatChannelListVC()
        testVC.mockedCurrentUserController = mockedCurrentUserController
        vc = testVC
        
        vc.controller = mockedChannelListController
        
        var uiConfig = UIConfig()
        uiConfig.navigation.channelListRouter = ChatChannelListRouter_Mock<NoExtraData>.self
        vc.uiConfig = uiConfig
        
        NSTimeZone.default = TimeZone(secondsFromGMT: 0)!
    }
    
    func test_chatChannelList_isPopulated() {
        let channel = ChatChannel.mock(
            cid: .unique,
            name: "Channel 1",
            imageURL: TestImages.yoda.url,
            lastMessageAt: .init(timeIntervalSince1970: 1_611_951_526_000)
        )
        let channelWithOnlineIndicator = ChatChannel.mockDMChannel(
            lastMessageAt: .init(timeIntervalSince1970: 1_611_951_527_000),
            members: [.mock(id: .unique, name: "Darth Vader", imageURL: TestImages.vader.url, isOnline: true)]
        )
        let channelWithLongTextAndUnreadCount = ChatChannel.mock(
            cid: .init(type: .messaging, id: "test_channel3"),
            name: "This is a channel with a big name. Really big.",
            imageURL: TestImages.yoda.url,
            lastMessageAt: .init(timeIntervalSince1970: 1_611_951_528_000),
            unreadCount: .mock(messages: 4),
            latestMessages: [
                ChatMessage.mock(
                    id: "1", text: "This is a long message. How the UI will adjust?", author: .mock(id: "Vader2")
                )
            ]
        )
        let channelWithMultipleMessages = ChatChannel.mock(
            cid: .init(type: .messaging, id: "test_channel4"),
            name: "Channel 4",
            imageURL: TestImages.vader.url,
            lastMessageAt: .init(timeIntervalSince1970: 1_611_951_529_000),
            latestMessages: [
                ChatMessage.mock(id: "2", text: "Hello", author: .mock(id: "Vader")),
                ChatMessage.mock(id: "1", text: "Hello2", author: .mock(id: "Vader2"))
            ]
        )
        mockedChannelListController.simulate(
            channels: [
                channel,
                channelWithOnlineIndicator,
                channelWithLongTextAndUnreadCount,
                channelWithMultipleMessages
            ],
            changes: []
        )
        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }
    
    func test_router_openCreateNewChannel() {
        vc.executeLifecycleMethods()
        
        vc.createNewChannelButton.simulateEvent(.touchUpInside)
        XCTAssertTrue(mockedRouter.openCreateNewChannelCalled)
    }
    
    func test_router_openCurrentUserProfile() {
        vc.executeLifecycleMethods()
        
        vc.userAvatarView.simulateEvent(.touchUpInside)
        XCTAssertEqual(mockedRouter.openCurrentUserProfile_currentUser, vc.userAvatarView.controller?.currentUser)
    }
    
    func test_router_openChat() {
        vc.executeLifecycleMethods()
        
        let channel = ChatChannel.mock(
            cid: .unique,
            name: "Channel",
            imageURL: TestImages.yoda.url
        )
        
        mockedChannelListController.simulate(channels: [channel], changes: [])
                
        vc.collectionView(vc.collectionView, didSelectItemAt: IndexPath(item: 0, section: 0))
        XCTAssertEqual(mockedRouter.openChat_channel, vc.controller.channels.first)
    }
    
    func test_chatChannelList_isEmpty() {
        // TODO, no empty states implemented yet.
    }
}
