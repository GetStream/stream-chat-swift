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
    var mockedCurrentUserController: CurrentUserController_Mock!

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
        mockedCurrentUserController = CurrentUserController_Mock()
        vc = ChatThreadListVC(
            threadListController: mockedThreadListController,
            currentUserController: mockedCurrentUserController,
            eventsController: mockedThreadListController.client.eventsController()
        )
        vc.setUpLayout()
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

    func test_defaultAppearance() {
        mockedThreadListController.state = .remoteDataFetched
        mockedThreadListController.threads_mock = mockThreads
        vc.controller(mockedThreadListController, didChangeState: .initialized)
        vc.controller(mockedThreadListController, didChangeThreads: [])
        vc.setUpLayout()
        AssertSnapshot(vc)
    }

    func test_unreadThreadsAppearance() {
        let unreadCount = UnreadCount(channels: 0, messages: 0, threads: 8)
        mockedThreadListController.state = .remoteDataFetched
        mockedThreadListController.threads_mock = mockThreads
        vc.controller(mockedThreadListController, didChangeState: .initialized)
        vc.controller(mockedThreadListController, didChangeThreads: [])
        vc.currentUserController(mockedCurrentUserController, didChangeCurrentUserUnreadCount: unreadCount)
        vc.showThreadsBannerView()
        vc.setUpLayout()
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
    }

    func test_handleStateChanges_whenRemoteDataFetched_whenThreadNotEmpty() {
        mockedThreadListController.threads_mock = mockThreads
        vc.handleStateChanges(.remoteDataFetched)
        XCTAssertEqual(vc.loadingView.isHidden, true)
        XCTAssertEqual(vc.emptyView.isHidden, true)
    }

    // MARK: - didReceiveEvent

    func test_didReceiveEvent_whenNewThreadReply_thenShowThreadsBannerView() {
        let newThreadMessageEvent = ThreadMessageNewEvent(
            message: .mock(parentMessageId: .unique),
            channel: .mock(cid: .unique),
            createdAt: .unique
        )
        vc.eventsController(
            mockedThreadListController.client.eventsController(),
            didReceiveEvent: newThreadMessageEvent
        )
        XCTAssertEqual(vc.tableView.tableHeaderView, vc.threadsBannerView)
    }

    func test_didReceiveEvent_whenNewThreadReply_whenThreadAlreadyLocal_thenThreadsBannerViewHidden() throws {
        let parentMessageId = MessageId.unique
        let newThreadMessageEvent = ThreadMessageNewEvent(
            message: .mock(parentMessageId: parentMessageId),
            channel: .mock(cid: .unique),
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
}
