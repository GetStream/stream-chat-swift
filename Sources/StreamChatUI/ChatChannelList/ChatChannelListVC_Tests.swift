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
    
    override func setUp() {
        super.setUp()
        mockedChannelListController = ChatChannelListController_Mock.mock()
        mockedCurrentUserController = CurrentChatUserController_Mock.mock()
        mockedCurrentUserController.currentUser_mock = .init(
            id: "Yoda",
            imageURL: TestImages.yoda.url
        )
        
        vc = ChatChannelListVC()
        vc.controller = mockedChannelListController
        vc.userAvatarView.controller = mockedCurrentUserController
        
        NSTimeZone.default = TimeZone(secondsFromGMT: 0)!
    }
    
    func test_chatChannelList_isPopulated() {
        let imageUrl = TestImages.vader.url

        let channel = ChatChannel.mock(
            cid: .init(type: .messaging, id: "test_channel1"),
            name: "Channel 1",
            imageURL: imageUrl,
            lastMessageAt: .init(timeIntervalSince1970: 1_611_951_526_000)
        )
        let channelWithOnlineIndicator = ChatChannel.mock(
            cid: .init(type: .messaging, id: "!members:test_channel2"),
            name: "Channel 2",
            imageURL: imageUrl,
            lastMessageAt: .init(timeIntervalSince1970: 1_611_951_527_000),
            members: [.mock(id: "luke", name: "Luke Skywalker", isOnline: true)]
        )
        let channelWithLongTextAndUnreadCount = ChatChannel.mock(
            cid: .init(type: .messaging, id: "test_channel3"),
            name: "Channel 3",
            imageURL: imageUrl,
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
            imageURL: imageUrl,
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
    
    func test_chatChannelList_isEmpty() {
        // TODO, no empty states implemented yet.
    }
}
