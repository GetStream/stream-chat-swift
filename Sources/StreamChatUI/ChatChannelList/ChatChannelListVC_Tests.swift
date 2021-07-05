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
        mockedCurrentUserController.currentUser_mock = .mock(
            id: "Yoda",
            imageURL: TestImages.yoda.url
        )

        let testVC = TestChatChannelListVC()
        testVC.mockedCurrentUserController = mockedCurrentUserController
        vc = testVC
        vc.controller = mockedChannelListController
        
        var components = Components()
        components.channelListRouter = ChatChannelListRouter_Mock<NoExtraData>.self
        vc.components = components

        channels = .dummy()
    }

    override func tearDown() {
        vc = nil
        view = nil
        mockedChannelListController = nil
        mockedCurrentUserController = nil
        
        super.tearDown()
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

    func test_appearanceCustomization_usingComponents() {
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

        var components = Components()
        components.channelCellSeparator = TestView.self

        vc.components = components

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
                if let listLayout = collectionViewLayout as? ListCollectionViewLayout {
                    listLayout.separatorHeight = 4
                }
            }
        }

        let vc = TestView()
        vc.controller = mockedChannelListController
        
        var components = Components()
        components.channelCellSeparator = TestSeparatorView.self
        vc.components = components

        mockedChannelListController.simulate(
            channels: channels,
            changes: []
        )
        AssertSnapshot(vc, isEmbeddedInNavigationController: true, variants: .onlyUserInterfaceStyles)
    }
    
    func test_router_openCurrentUserProfile() {
        vc.executeLifecycleMethods()
        
        vc.userAvatarView.simulateEvent(.touchUpInside)
        XCTAssertTrue(mockedRouter.openCurrentUserProfileCalled)
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
        XCTAssertEqual(mockedRouter.openChat_channelId, vc.controller.channels.first?.cid)
    }

    func test_channelList_loadsNextChannels_whenScrolledToBottom() {
        let channelListVC = ChatChannelListVC()
        channelListVC.controller = mockedChannelListController
        // There are just 3 items mocked, so it's okay to add content offset of 1000,
        // because the scrollView will definitely be scrolled most-down
        channelListVC.collectionView.contentOffset = .init(x: 0, y: 1000)
        channelListVC.scrollViewDidEndDecelerating(channelListVC.collectionView)
        XCTAssertTrue(mockedChannelListController.loadNextChannelsIsCalled)
    }

    func test_usesCorrectComponentsTypes_whenCustomTypesDefined() {
        // Create default ChatChannelListVC which has everything default from `Components`
        let channelListVC = ChatChannelListVC()

        class OtherCollectionLayout: UICollectionViewLayout {}

        // Create new config to edit types...
        var components = channelListVC.components
        components.channelListLayout = OtherCollectionLayout.self
        channelListVC.components = components

        XCTAssert(channelListVC.collectionViewLayout is OtherCollectionLayout)
    }
}

// MARK: - Tests for temporary fix for channel list changes crash

extension ChatChannelListVC_Tests {
    func test_didChangeChannels_whenNoConflicts_performBatchUpdates() {
        let channelListVC = FakeChatChannelListVC()
        channelListVC.controller = mockedChannelListController

        let noConflictChanges: [ListChange<_ChatChannel<NoExtraData>>] = [
            .update(.mock(cid: .unique), index: .init(row: 1, section: 0)),
            .update(.mock(cid: .unique), index: .init(row: 2, section: 0)),
            .insert(.mock(cid: .unique), index: .init(row: 3, section: 0)),
            .remove(.mock(cid: .unique), index: .init(row: 4, section: 0))
        ]

        mockedChannelListController.simulate(
            channels: [.mock(cid: .unique), .mock(cid: .unique), .mock(cid: .unique)],
            changes: noConflictChanges
        )

        channelListVC.controller(mockedChannelListController, didChangeChannels: noConflictChanges)
        XCTAssertEqual(channelListVC.mockedCollectionView.performBatchUpdatesCallCount, 1)
        XCTAssertEqual(channelListVC.mockedCollectionView.reloadDataCallCount, 0)
    }

    func test_didChangeChannels_whenHasRemoveConflicts_reloadData() {
        let channelListVC = FakeChatChannelListVC()
        channelListVC.controller = mockedChannelListController

        let hasConflictChanges: [ListChange<_ChatChannel<NoExtraData>>] = [
            .update(.mock(cid: .unique), index: .init(row: 1, section: 0)),
            .update(.mock(cid: .unique), index: .init(row: 2, section: 0)),
            .insert(.mock(cid: .unique), index: .init(row: 3, section: 0)),
            .remove(.mock(cid: .unique), index: .init(row: 3, section: 0))
        ]

        mockedChannelListController.simulate(
            channels: [.mock(cid: .unique), .mock(cid: .unique), .mock(cid: .unique)],
            changes: hasConflictChanges
        )

        channelListVC.controller(mockedChannelListController, didChangeChannels: hasConflictChanges)
        XCTAssertEqual(channelListVC.mockedCollectionView.performBatchUpdatesCallCount, 0)
        XCTAssertEqual(channelListVC.mockedCollectionView.reloadDataCallCount, 1)
    }

    func test_didChangeChannels_whenHasMoveConflicts_reloadData() {
        let channelListVC = FakeChatChannelListVC()
        channelListVC.controller = mockedChannelListController

        let hasConflictChanges: [ListChange<_ChatChannel<NoExtraData>>] = [
            .update(.mock(cid: .unique), index: .init(row: 1, section: 0)),
            .update(.mock(cid: .unique), index: .init(row: 2, section: 0)),
            .insert(.mock(cid: .unique), index: .init(row: 3, section: 0)),
            .move(.mock(cid: .unique), fromIndex: .init(row: 3, section: 0), toIndex: .init(row: 4, section: 0))
        ]

        mockedChannelListController.simulate(
            channels: [.mock(cid: .unique), .mock(cid: .unique), .mock(cid: .unique)],
            changes: hasConflictChanges
        )

        channelListVC.controller(mockedChannelListController, didChangeChannels: hasConflictChanges)
        XCTAssertEqual(channelListVC.mockedCollectionView.performBatchUpdatesCallCount, 0)
        XCTAssertEqual(channelListVC.mockedCollectionView.reloadDataCallCount, 1)
    }

    func test_didChangeChannels_whenHasInsertConflicts_reloadData() {
        let channelListVC = FakeChatChannelListVC()
        channelListVC.controller = mockedChannelListController

        let hasConflictChanges: [ListChange<_ChatChannel<NoExtraData>>] = [
            .update(.mock(cid: .unique), index: .init(row: 1, section: 0)),
            .update(.mock(cid: .unique), index: .init(row: 2, section: 0)),
            .insert(.mock(cid: .unique), index: .init(row: 3, section: 0)),
            .insert(.mock(cid: .unique), index: .init(row: 2, section: 0))
        ]

        mockedChannelListController.simulate(
            channels: [.mock(cid: .unique), .mock(cid: .unique), .mock(cid: .unique)],
            changes: hasConflictChanges
        )

        channelListVC.controller(mockedChannelListController, didChangeChannels: hasConflictChanges)
        XCTAssertEqual(channelListVC.mockedCollectionView.performBatchUpdatesCallCount, 0)
        XCTAssertEqual(channelListVC.mockedCollectionView.reloadDataCallCount, 1)
    }

    func test_didChangeChannels_whenHasUpdateConflicts_reloadData() {
        let channelListVC = FakeChatChannelListVC()
        channelListVC.controller = mockedChannelListController

        let hasConflictChanges: [ListChange<_ChatChannel<NoExtraData>>] = [
            .update(.mock(cid: .unique), index: .init(row: 1, section: 0)),
            .update(.mock(cid: .unique), index: .init(row: 2, section: 0)),
            .insert(.mock(cid: .unique), index: .init(row: 3, section: 0)),
            .update(.mock(cid: .unique), index: .init(row: 3, section: 0))
        ]

        mockedChannelListController.simulate(
            channels: [.mock(cid: .unique), .mock(cid: .unique), .mock(cid: .unique)],
            changes: hasConflictChanges
        )

        channelListVC.controller(mockedChannelListController, didChangeChannels: hasConflictChanges)
        XCTAssertEqual(channelListVC.mockedCollectionView.performBatchUpdatesCallCount, 0)
        XCTAssertEqual(channelListVC.mockedCollectionView.reloadDataCallCount, 1)
    }

    private class FakeChatChannelListVC: ChatChannelListVC {
        var mockedCollectionView: MockCollectionView = MockCollectionView()
        override var collectionView: UICollectionView {
            mockedCollectionView
        }

        class MockCollectionView: UICollectionView {
            init() {
                super.init(frame: .zero, collectionViewLayout: .init())
            }

            @available(*, unavailable)
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }

            var reloadDataCallCount = 0
            override func reloadData() {
                reloadDataCallCount += 1
            }

            var performBatchUpdatesCallCount = 0
            override func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
                performBatchUpdatesCallCount += 1
            }
        }
    }
}
