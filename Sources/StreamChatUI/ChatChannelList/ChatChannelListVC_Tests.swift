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

    var channels: [ChatChannel] = []
    
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
        channels = [
            channel,
            channelWithOnlineIndicator,
            channelWithLongTextAndUnreadCount,
            channelWithMultipleMessages
        ]
        
        NSTimeZone.default = TimeZone(secondsFromGMT: 0)!
    }

    override func tearDown() {
        super.tearDown()
        
        vc = nil
        view = nil
        mockedChannelListController = nil
        mockedCurrentUserController = nil
    }

    func test_emptyAppearance() {
        mockedChannelListController.simulateInitial(
            channels: [],
            state: .remoteDataFetched
        )
        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }
    
    func test_defaultAppearance() {
        mockedChannelListController.simulate(
            channels: channels,
            changes: []
        )
        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }

    func test_appearanceCustomization_usingUIConfig() {
        class TestView: CellSeparatorReusableView {
            override func setUpAppearance() {
                super.setUpAppearance()

                separatorView.backgroundColor = UIColor.gray
            }

            override func setUpLayout() {
                super.setUpLayout()

                separatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15).isActive = true
            }
        }

        var config = UIConfig()
        config.channelList.cellSeparatorReusableView = TestView.self

        vc.uiConfig = config

        mockedChannelListController.simulateInitial(
            channels: channels,
            state: .remoteDataFetched
        )
        AssertSnapshot(vc, isEmbeddedInNavigationController: true, variants: .onlyUserInterfaceStyles)
    }

    func test_appearanceCustomization_usingAppearanceHook() {
        class TestSeparatorView: CellSeparatorReusableView {}
        class TestView: TestChatChannelListVC {}

        TestView.defaultAppearance {
            $0.createNewChannelButton.tintColor = UIColor.orange

            if let listLayout = $0.collectionViewLayout as? ListCollectionViewLayout {
                listLayout.separatorHeight = 4
            }

            TestSeparatorView.defaultAppearance {
                $0.separatorView.backgroundColor = UIColor.orange
            }
        }

        let vc = TestView()
        vc.controller = mockedChannelListController
        
        var config = UIConfig()
        config.channelList.cellSeparatorReusableView = TestSeparatorView.self
        vc.uiConfig = config

        mockedChannelListController.simulateInitial(
            channels: channels,
            state: .remoteDataFetched
        )
        AssertSnapshot(vc, isEmbeddedInNavigationController: true, variants: .onlyUserInterfaceStyles)
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestSeparatorView: CellSeparatorReusableView {
            override func setUpAppearance() {
                super.setUpAppearance()
                separatorView.backgroundColor = UIColor.orange
            }
        }

        class TestView: TestChatChannelListVC {
            override func setUpAppearance() {
                super.setUpAppearance()
                createNewChannelButton.tintColor = UIColor.orange
                if let listLayout = collectionViewLayout as? ListCollectionViewLayout {
                    listLayout.separatorHeight = 4
                }
            }
        }

        let vc = TestView()
        vc.controller = mockedChannelListController
        
        var config = UIConfig()
        config.channelList.cellSeparatorReusableView = TestSeparatorView.self
        vc.uiConfig = config

        mockedChannelListController.simulate(
            channels: channels,
            changes: []
        )
        AssertSnapshot(vc, isEmbeddedInNavigationController: true, variants: .onlyUserInterfaceStyles)
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

        mockedChannelListController.simulateInitial(
            channels: [channel],
            state: .remoteDataFetched
        )
                
        vc.collectionView(vc.collectionView, didSelectItemAt: IndexPath(item: 0, section: 0))
        XCTAssertEqual(mockedRouter.openChat_channel, vc.controller.channels.first)
    }

}
