//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import UIKit
import XCTest

final class PollResultsVoteListVC_Tests: XCTestCase {
    // Note: Table cells won't have the correct corner radius,
    // due to this issue: https://github.com/pointfreeco/swift-snapshot-testing/issues/358

    let currentUser = ChatUser.mock(
        id: .unique,
        name: "José Mourinho"
    )

    lazy var pollFactory = PollMockFactory(currentUser: currentUser)

    func test_appearance() {
        let poll = pollFactory.makePoll(isClosed: true)
        let pollOption = poll.options[1]
        let votes = pollOption.latestVotes
        let controller = PollVoteListController_Mock()
        controller.mockedVotes = votes
        let voteListVC = PollResultsVoteListVC(
            pollVoteListController: controller,
            poll: poll,
            option: pollOption
        )
        voteListVC.controller(controller, didChangeVotes: [])

        AssertSnapshot(voteListVC)
    }
}

class PollVoteListController_Mock: PollVoteListController {
    init() {
        super.init(query: .init(pollId: .unique), client: .mock)
    }

    var mockedVotes: [PollVote] = []
    override var votes: LazyCachedMapCollection<PollVote> {
        LazyCachedMapCollection(elements: mockedVotes)
    }
}
