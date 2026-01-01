//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import UIKit
import XCTest

final class PollCommentListVC_Tests: XCTestCase {
    // Note: Table cells won't have the correct corner radius,
    // due to this issue: https://github.com/pointfreeco/swift-snapshot-testing/issues/358

    let currentUser = ChatUser.mock(
        id: .unique,
        name: "José Mourinho"
    )

    lazy var pollFactory = PollMockFactory(currentUser: currentUser)

    var comments: [PollVote] {
        [
            .mock(
                createdAt: "2024-07-26T12:25:07.25741Z".toDate(),
                answerText: "So cool",
                user: .mock(id: .unique, name: "Ronaldo")
            ),
            .mock(
                createdAt: "2024-07-26T12:25:07.25741Z".toDate(),
                answerText: "Ahah",
                user: .mock(id: .unique, name: "Messi")
            ),
            .mock(
                createdAt: "2024-07-26T12:25:07.25741Z".toDate(),
                answerText: "Great!",
                user: .mock(id: .unique, name: "Figo")
            )
        ]
    }

    func test_appearance() {
        let poll = pollFactory.makePoll(
            isClosed: true,
            latestAnswers: comments
        )
        let comments = poll.latestAnswers
        let commentsController = PollVoteListController_Mock()
        commentsController.mockedVotes = comments
        let mockClient = ChatClient_Mock.mock
        mockClient.currentUserId_mock = currentUser.id
        let pollController = PollController_Mock(client: mockClient)
        pollController.mockedPoll = poll
        let voteListVC = PollCommentListVC(
            pollController: pollController,
            commentsController: commentsController
        )
        voteListVC.controller(commentsController, didChangeVotes: [])

        AssertSnapshot(voteListVC)
    }

    func test_appearance_whenAlreadyCommented() {
        let myComment = PollVote.mock(
            createdAt: "2024-05-23T12:25:07.25741Z".toDate(),
            answerText: "My Comment",
            user: currentUser
        )
        let poll = pollFactory.makePoll(
            isClosed: true,
            latestAnswers: comments + [myComment]
        )
        let comments = poll.latestAnswers
        let commentsController = PollVoteListController_Mock()
        commentsController.mockedVotes = comments
        let mockClient = ChatClient_Mock.mock
        mockClient.currentUserId_mock = currentUser.id
        let pollController = PollController_Mock(client: mockClient)
        pollController.mockedPoll = poll
        let voteListVC = PollCommentListVC(
            pollController: pollController,
            commentsController: commentsController
        )
        voteListVC.controller(commentsController, didChangeVotes: [])

        AssertSnapshot(voteListVC)
    }
}
