//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class ChatChannelListVC_Tests: XCTestCase {
    var view: ChatChannelListItemView!
    var vc: ChatChannelListVC!
    var mockedChannelListController: ChatChannelListController_Mock!
    var mockedCurrentUserController: CurrentChatUserController_Mock!
    var mockedRouter: ChatChannelListRouterMock { vc.router as! ChatChannelListRouterMock }

    var channels: [ChatChannel] = []

    // Workaround for setting mockedCurrentUserController to userAvatarView.
    class TestChatChannelListVC: ChatChannelListVC {
        var mockedCurrentUserController: CurrentChatUserController_Mock?

        override func setUp() {
            super.setUp()
            userAvatarView.components = .mock
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
        testVC.components = .mock
        testVC.mockedCurrentUserController = mockedCurrentUserController
        vc = testVC
        vc.controller = mockedChannelListController

        var components = Components.mock
        components.channelListRouter = ChatChannelListRouterMock.self
        vc.components = components
        vc.appearance.formatters.channelListMessageTimestamp = DefaultMessageTimestampFormatter()

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
        vc.components.isChatChannelListStatesEnabled = true
        vc.executeLifecycleMethods()
        mockedChannelListController.simulate(state: .remoteDataFetched)
        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }

    func test_defaultAppearance() {
        mockedChannelListController.simulate(
            channels: channels,
            changes: []
        )
        vc.reloadChannels()
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

        var components = Components.mock
        components.isChatChannelListStatesEnabled = false
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
        vc.appearance.formatters.channelListMessageTimestamp = DefaultMessageTimestampFormatter()

        var components = Components.mock
        components.channelCellSeparator = TestSeparatorView.self
        vc.components = components

        mockedChannelListController.simulate(
            channels: channels,
            changes: []
        )
        vc.reloadChannels()
        AssertSnapshot(vc, isEmbeddedInNavigationController: true, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_withSearchBar() {
        vc.components.channelListSearchStrategy = .messages
        mockedChannelListController.channels_mock = channels
        mockedChannelListController.simulate(state: .remoteDataFetched)
        vc.executeLifecycleMethods()
        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }

    func test_makeChatChannelListVC() {
        let mockedController = ChatChannelListController_Mock.mock()
        let mockChatChannelListVC = TestChatChannelListVC.make(with: mockedController)

        XCTAssertNotNil(mockChatChannelListVC)
        XCTAssert(mockChatChannelListVC.isKind(of: ChatChannelListVC.self))
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

        mockedChannelListController.channels_mock = [channel]
        vc.reloadChannels()

        vc.collectionView(vc.collectionView, didSelectItemAt: IndexPath(item: 0, section: 0))
        XCTAssertEqual(mockedRouter.openChat_channelId, channel.cid)
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

    func test_didChangeState_whenRemoteDataFetchedAndChannelsAreEmpty_thenEmptyViewIsShown() {
        // GIVEN
        let emptyViewHidden = false
        vc.components.isChatChannelListStatesEnabled = true

        // WHEN
        vc.controller(vc.controller, didChangeState: .remoteDataFetched)

        // THEN
        XCTAssertEqual(emptyViewHidden, vc.emptyView.isHidden)
    }

    func test_didChangeState_whenRemoteDataFetchedFailed_thenErrorViewIsShown() {
        // GIVEN
        let errorViewHidden = false
        vc.components.isChatChannelListStatesEnabled = true

        // WHEN
        vc.controller(vc.controller, didChangeState: .remoteDataFetchFailed(ClientError()))

        // THEN
        XCTAssertEqual(errorViewHidden, vc.channelListErrorView.isHidden)
    }

    func test_didChangeState_whenLocalDataFetched_whenChannelsNotEmpty_shouldHideLoadingView() {
        vc.components.isChatChannelListStatesEnabled = true
        mockedChannelListController.channels_mock = [.mock(cid: .unique)]
        vc.chatChannelListLoadingView.isHidden = false

        vc.controller(mockedChannelListController, didChangeState: .localDataFetched)

        XCTAssertEqual(vc.chatChannelListLoadingView.isHidden, true)
    }

    func test_didChangeState_whenLocalDataFetched_whenChannelsEmpty_shouldShowLoadingView() {
        vc.components.isChatChannelListStatesEnabled = true
        mockedChannelListController.channels_mock = []
        vc.chatChannelListLoadingView.isHidden = true

        vc.controller(mockedChannelListController, didChangeState: .localDataFetched)

        XCTAssertEqual(vc.chatChannelListLoadingView.isHidden, false)
    }

    func test_didChangeState_whenInitialized_whenChannelsNotEmpty_shouldHideLoadingView() {
        vc.components.isChatChannelListStatesEnabled = true
        mockedChannelListController.channels_mock = [.mock(cid: .unique)]
        vc.chatChannelListLoadingView.isHidden = false

        vc.controller(mockedChannelListController, didChangeState: .initialized)

        XCTAssertEqual(vc.chatChannelListLoadingView.isHidden, true)
    }

    func test_didChangeState_whenInitialized_whenChannelsEmpty_shouldShowLoadingView() {
        vc.components.isChatChannelListStatesEnabled = true
        mockedChannelListController.channels_mock = []
        vc.chatChannelListLoadingView.isHidden = true

        vc.controller(mockedChannelListController, didChangeState: .initialized)

        XCTAssertEqual(vc.chatChannelListLoadingView.isHidden, false)
    }

    func test_shouldAddNewChannelToList_whenCurrentUserIsMember_shouldReturnTrue() {
        let channelListVC = FakeChatChannelListVC()
        channelListVC.controller = mockedChannelListController

        let channel = ChatChannel.mock(cid: .unique, membership: .mock(id: .unique))
        XCTAssertTrue(channelListVC.controller(mockedChannelListController, shouldAddNewChannelToList: channel))
    }

    func test_shouldAddNewChannelToList_whenCurrentUserIsNotMember_shouldReturnFalse() {
        let channelListVC = FakeChatChannelListVC()
        channelListVC.controller = mockedChannelListController

        let channel = ChatChannel.mock(cid: .unique, membership: nil)
        XCTAssertFalse(channelListVC.controller(mockedChannelListController, shouldAddNewChannelToList: channel))
    }

    func test_shouldListUpdatedChannel_whenCurrentUserIsMember_shouldReturnTrue() {
        let channelListVC = FakeChatChannelListVC()
        channelListVC.controller = mockedChannelListController

        let channel = ChatChannel.mock(cid: .unique, membership: .mock(id: .unique))
        XCTAssertTrue(channelListVC.controller(mockedChannelListController, shouldListUpdatedChannel: channel))
    }

    func test_shouldListUpdatedChannel_whenCurrentUserIsNotMember_shouldReturnFalse() {
        let channelListVC = FakeChatChannelListVC()
        channelListVC.controller = mockedChannelListController

        let channel = ChatChannel.mock(cid: .unique, membership: nil)
        XCTAssertFalse(channelListVC.controller(mockedChannelListController, shouldListUpdatedChannel: channel))
    }

    func test_didChangeChannels_whenIsNotVisible_dontUpdateData_setSkippedRendering() {
        let channelListVC = FakeChatChannelListVC()
        channelListVC.controller = mockedChannelListController
        channelListVC.shouldMockViewIfLoaded = false
        XCTAssertEqual(channelListVC.skippedRendering, false)

        channelListVC.controller(mockedChannelListController, didChangeChannels: [])

        XCTAssertEqual(channelListVC.mockedCollectionView.performBatchUpdatesCallCount, 0)
        XCTAssertEqual(channelListVC.mockedCollectionView.reloadDataCallCount, 0)
        XCTAssertEqual(channelListVC.skippedRendering, true)
    }

    func test_didChangeChannels_whenEmptyViewVisible_whenNewChannelsNotEmpty_shouldHideEmptyView() {
        let channelListVC = FakeChatChannelListVC()
        channelListVC.components.isChatChannelListStatesEnabled = true
        channelListVC.controller = mockedChannelListController
        mockedChannelListController.state_mock = .remoteDataFetched
        mockedChannelListController.channels_mock = [.mock(cid: .unique)]
        channelListVC.emptyView.isHidden = false

        channelListVC.viewWillAppear(false)
        channelListVC.controller(mockedChannelListController, didChangeChannels: [])

        XCTAssertEqual(channelListVC.emptyView.isHidden, true)
    }

    func test_didChangeChannels_whenEmptyViewHidden_whenNewChannelsIsEmpty_shouldShowEmptyView() {
        let channelListVC = FakeChatChannelListVC()
        channelListVC.components.isChatChannelListStatesEnabled = true
        channelListVC.controller = mockedChannelListController
        mockedChannelListController.state_mock = .remoteDataFetched
        mockedChannelListController.channels_mock = []
        channelListVC.emptyView.isHidden = true

        channelListVC.viewWillAppear(false)
        channelListVC.controller(mockedChannelListController, didChangeChannels: [])

        XCTAssertEqual(channelListVC.emptyView.isHidden, false)
    }

    func test_viewWillAppear_whenSkippedRendering_shouldReloadData() {
        let channelListVC = FakeChatChannelListVC()
        channelListVC.controller = mockedChannelListController
        channelListVC.shouldMockViewIfLoaded = false
        mockedChannelListController.channels_mock = [.mock(cid: .unique), .mock(cid: .unique)]
        channelListVC.controller(mockedChannelListController, didChangeChannels: [])
        XCTAssertEqual(channelListVC.skippedRendering, true)
        XCTAssertEqual(channelListVC.skipChannelUpdates, true)
        
        channelListVC.viewWillAppear(false)

        XCTAssertEqual(channelListVC.skippedRendering, false)
        XCTAssertEqual(channelListVC.skipChannelUpdates, false)
        XCTAssertEqual(channelListVC.reloadChannelsCallCount, 1)
    }
    
    func test_swipeableViewActionViews() {
        mockedChannelListController.channels_mock = [.mock(cid: .unique, ownCapabilities: [.deleteChannel])]
        let channelListVC = ChatChannelListVC()
        channelListVC.controller = mockedChannelListController
        channelListVC.reloadChannels()

        let swipeViews = channelListVC.swipeableViewActionViews(for: IndexPath(item: 0, section: 0))
        let swipeViewIdentifiers = Set(swipeViews.compactMap(\.accessibilityIdentifier))
        XCTAssertEqual(swipeViewIdentifiers, Set(["deleteView", "moreView"]))
    }

    func test_swipeableViewActionViews_whenCantDeleteChannel() {
        mockedChannelListController.channels_mock = [.mock(cid: .unique, ownCapabilities: [])]
        let channelListVC = ChatChannelListVC()
        channelListVC.controller = mockedChannelListController
        channelListVC.reloadChannels()

        let swipeViews = channelListVC.swipeableViewActionViews(for: IndexPath(item: 0, section: 0))
        let swipeViewIdentifiers = Set(swipeViews.compactMap(\.accessibilityIdentifier))
        XCTAssertFalse(channelListVC.channels.isEmpty)
        XCTAssertEqual(swipeViewIdentifiers, Set(["moreView"]))
    }

    private class FakeChatChannelListVC: ChatChannelListVC {
        var mockedCollectionView: MockCollectionView = MockCollectionView()
        override var collectionView: UICollectionView {
            mockedCollectionView
        }

        var reloadChannelsCallCount = 0
        override func reloadChannels() {
            reloadChannelsCallCount += 1
        }

        class MockView: UIView {
            override var window: UIWindow? {
                UIWindow(frame: .zero)
            }
        }

        var shouldMockViewIfLoaded = true
        override var viewIfLoaded: UIView? {
            if shouldMockViewIfLoaded {
                return MockView()
            }
            return nil
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
