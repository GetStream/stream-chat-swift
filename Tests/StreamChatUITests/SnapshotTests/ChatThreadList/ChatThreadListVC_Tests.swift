//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class ChatThreadListVC_Tests: XCTestCase {
    var vc: ChatThreadListVC!
    var mockedThreadListController: ChatThreadListController_Mock!

    var mockYoda = ChatUser.mock(id: .unique, name: "Yoda")
    var mockVader = ChatUser.mock(id: .unique, name: "Vader")
    var mockThreads: [ChatThread] = []

    override func setUp() {
        super.setUp()

        mockThreads = [
            .mock(
                parentMessage: .mock(text: "Parent Message", author: mockYoda),
                channel: .mock(cid: .unique, name: "Star Wars Channel"),
                createdBy: mockVader,
                replyCount: 3,
                participantCount: 2,
                threadParticipants: [
                    .mock(user: mockYoda),
                    .mock(user: mockVader)
                ],
                lastMessageAt: .unique,
                createdAt: .unique,
                updatedAt: .unique,
                title: nil,
                latestReplies: [
                    .mock(text: "First Message", author: mockYoda),
                    .mock(text: "Second Message", author: mockVader),
                    .mock(text: "Third Message", author: mockYoda)
                ],
                reads: [
                    .mock(user: mockYoda, unreadMessagesCount: 6)
                ],
                extraData: [:]
            ),
            .mock(
                parentMessage: .mock(text: "Parent Message 2", author: mockYoda),
                channel: .mock(cid: .unique, name: "Marvel Channel"),
                createdBy: mockVader,
                replyCount: 3,
                participantCount: 2,
                threadParticipants: [
                    .mock(user: mockYoda),
                    .mock(user: mockVader)
                ],
                lastMessageAt: .unique,
                createdAt: .unique,
                updatedAt: .unique,
                title: nil,
                latestReplies: [
                    .mock(text: "First Message", author: mockVader)
                ],
                reads: [],
                extraData: [:]
            )
        ]

        let clientMock = ChatClient.mock
        clientMock.currentUserId_mock = mockYoda.id
        mockedThreadListController = .mock(
            query: .init(watch: true),
            client: clientMock
        )
        vc = ChatThreadListVC(
            threadListController: mockedThreadListController,
            eventsController: mockedThreadListController.client.eventsController()
        )
        vc.setUpLayout()
        mockedThreadListController.synchronize_callCount = 0
    }

    override func tearDown() {
        super.tearDown()

        vc = nil
        mockedThreadListController = nil
    }

    // MARK: Snapshot Tests

    func test_emptyAppearance() {
        mockedThreadListController.state = .remoteDataFetched
        mockedThreadListController.threads_mock = []
        vc.controller(mockedThreadListController, didChangeState: .remoteDataFetched)
        AssertSnapshot(vc)
    }

    func test_loadingAppearance() {
        mockedThreadListController.state = .initialized
        mockedThreadListController.threads_mock = []
        vc.controller(mockedThreadListController, didChangeState: .initialized)
        AssertSnapshot(vc)
    }

    func test_errorAppearance() {
        mockedThreadListController.state = .initialized
        mockedThreadListController.threads_mock = []
        vc.controller(mockedThreadListController, didChangeState: .remoteDataFetchFailed(ClientError()))
        AssertSnapshot(vc)
    }

    func test_defaultAppearance() {
        mockedThreadListController.state = .remoteDataFetched
        mockedThreadListController.threads_mock = mockThreads
        vc.controller(mockedThreadListController, didChangeState: .initialized)
        vc.controller(mockedThreadListController, didChangeThreads: [])
        vc.setUpLayout()
        AssertSnapshot(vc)
    }

    func test_newThreadsAppearance() {
        class MockVC: ChatThreadListVC {
            override func viewWillAppear(_ animated: Bool) {
                // no - op
            }
        }
        vc = MockVC(
            threadListController: mockedThreadListController,
            eventsController: mockedThreadListController.client.eventsController()
        )

        mockedThreadListController.state = .remoteDataFetched
        mockedThreadListController.threads_mock = mockThreads
        vc.controller(mockedThreadListController, didChangeState: .initialized)
        vc.controller(mockedThreadListController, didChangeThreads: [])
        vc.setUpLayout()
        vc.showHeaderBannerView()
        vc.newAvailableThreadIds = [.unique, .unique]
        AssertSnapshot(vc)
    }

    // MARK: - handleStateChanges

    func test_handleStateChanges_whenInitialized_whenThreadAreEmpty() {
        mockedThreadListController.threads_mock = []
        vc.handleStateChanges(.initialized)
        XCTAssertEqual(vc.loadingView.isHidden, false)
        XCTAssertEqual(vc.emptyView.isHidden, true)
    }

    func test_handleStateChanges_whenInitialized_whenThreadNotEmpty() {
        mockedThreadListController.threads_mock = mockThreads
        vc.handleStateChanges(.initialized)
        XCTAssertEqual(vc.loadingView.isHidden, true)
        XCTAssertEqual(vc.emptyView.isHidden, true)
    }

    func test_handleStateChanges_whenLocalDataFetched_whenThreadAreEmpty() {
        mockedThreadListController.threads_mock = []
        vc.handleStateChanges(.localDataFetched)
        XCTAssertEqual(vc.loadingView.isHidden, false)
        XCTAssertEqual(vc.emptyView.isHidden, true)
    }

    func test_handleStateChanges_whenLocalDataFetch_whenThreadNotEmpty() {
        mockedThreadListController.threads_mock = mockThreads
        vc.handleStateChanges(.localDataFetched)
        XCTAssertEqual(vc.loadingView.isHidden, true)
        XCTAssertEqual(vc.emptyView.isHidden, true)
    }

    func test_handleStateChanges_whenRemoteDataFetched_whenThreadAreEmpty() {
        mockedThreadListController.threads_mock = []
        vc.handleStateChanges(.remoteDataFetched)
        XCTAssertEqual(vc.loadingView.isHidden, true)
        XCTAssertEqual(vc.emptyView.isHidden, false)
        XCTAssertEqual(vc.errorView.isHidden, true)
    }

    func test_handleStateChanges_whenRemoteDataFetched_whenThreadNotEmpty() {
        mockedThreadListController.threads_mock = mockThreads
        vc.handleStateChanges(.remoteDataFetched)
        XCTAssertEqual(vc.loadingView.isHidden, true)
        XCTAssertEqual(vc.emptyView.isHidden, true)
        XCTAssertEqual(vc.errorView.isHidden, true)
    }

    func test_handleStateChanges_whenRemoteDataFetchedFailed() {
        mockedThreadListController.threads_mock = mockThreads
        vc.handleStateChanges(.remoteDataFetchFailed(ClientError()))
        XCTAssertEqual(vc.loadingView.isHidden, true)
        XCTAssertEqual(vc.emptyView.isHidden, true)
        XCTAssertEqual(vc.errorView.isHidden, false)
    }

    // MARK: - didReceiveEvent

    func test_didReceiveEvent_whenNewThreadReply_whenViewIsVisible_thenShowThreadsBannerView() {
        vc.mockIsViewVisible(true)

        let newThreadMessageEvent = ThreadMessageNewEvent(
            message: .mock(parentMessageId: .unique),
            channel: .mock(cid: .unique),
            unreadCount: .noUnread,
            createdAt: .unique
        )
        vc.eventsController(
            mockedThreadListController.client.eventsController(),
            didReceiveEvent: newThreadMessageEvent
        )

        XCTAssertEqual(vc.tableView.tableHeaderView, vc.headerBannerView)
    }

    func test_didReceiveEvent_whenNewThreadReply_whenViewNotVisible_thenOnlyInsertNewAvialbleThreadIds() {
        vc.mockIsViewVisible(false)

        let expectedParentMessageId = MessageId.unique
        let newThreadMessageEvent = ThreadMessageNewEvent(
            message: .mock(parentMessageId: expectedParentMessageId),
            channel: .mock(cid: .unique),
            unreadCount: .noUnread,
            createdAt: .unique
        )
        vc.eventsController(
            mockedThreadListController.client.eventsController(),
            didReceiveEvent: newThreadMessageEvent
        )

        XCTAssertNil(vc.tableView.tableHeaderView)
        XCTAssertEqual(vc.newAvailableThreadIds, [expectedParentMessageId])
    }

    func test_didReceiveEvent_whenNewThreadReply_whenThreadAlreadyLocal_thenThreadsBannerViewHidden() throws {
        let parentMessageId = MessageId.unique
        let newThreadMessageEvent = ThreadMessageNewEvent(
            message: .mock(parentMessageId: parentMessageId),
            channel: .mock(cid: .unique),
            unreadCount: .noUnread,
            createdAt: .unique
        )
        try mockedThreadListController.dataStore.database.writeSynchronously { session in
            try session.saveThread(payload: .dummy(parentMessageId: parentMessageId), cache: nil)
        }
        vc.eventsController(
            mockedThreadListController.client.eventsController(),
            didReceiveEvent: newThreadMessageEvent
        )
        XCTAssertNil(vc.tableView.tableHeaderView)
    }

    // MARK: viewWillAppear

    func test_viewWillAppear_whenNewAvailableThreads_shouldRefetchThreadList() {
        vc.newAvailableThreadIds = [.unique]

        vc.viewWillAppear(false)

        XCTAssertEqual(mockedThreadListController.synchronize_callCount, 1)
    }

    func test_viewWillAppear_whenNoNewThreads_shouldNotRefetchThreadList() {
        vc.newAvailableThreadIds = []

        vc.viewWillAppear(false)

        XCTAssertEqual(mockedThreadListController.synchronize_callCount, 0)
    }

    // MARK: - didTapOnErrorView

    func test_didTapOnErrorView_shouldShowLoadingView() {
        mockedThreadListController.threads_mock = []
        vc.controller(vc.threadListController, didChangeThreads: [])

        vc.didTapOnErrorView()

        XCTAssertEqual(mockedThreadListController.synchronize_callCount, 1)
        AssertSnapshot(vc, variants: [.defaultLight, .defaultDark])
    }

    func test_didTapOnErrorView_whenThreadsNotEmpty_shouldShowLoadingHeaderBannerView() {
        mockedThreadListController.threads_mock = mockThreads
        vc.controller(vc.threadListController, didChangeThreads: [])

        vc.didTapOnErrorView()

        XCTAssertEqual(mockedThreadListController.synchronize_callCount, 1)
        AssertSnapshot(vc, variants: [.defaultLight, .defaultDark])
    }

    // MARK: - didTapOnHeaderBannerView

    func test_didTapOnHeaderBannerView_shouldShowLoadingHeaderBannerView() {
        mockedThreadListController.threads_mock = mockThreads
        vc.controller(vc.threadListController, didChangeThreads: [])

        vc.didTapOnHeaderBannerView()

        XCTAssertEqual(mockedThreadListController.synchronize_callCount, 1)
        AssertSnapshot(vc, variants: [.defaultLight, .defaultDark])
    }
}
