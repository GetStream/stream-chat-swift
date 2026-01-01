//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import UIKit
import XCTest

final class PollResultsVC_Tests: XCTestCase {
    // Note: Table cells won't have the correct corner radius,
    // due to this issue: https://github.com/pointfreeco/swift-snapshot-testing/issues/358

    let currentUser = ChatUser.mock(
        id: .unique,
        name: "José Mourinho"
    )

    lazy var pollFactory = PollMockFactory(currentUser: currentUser)

    func test_appearance() {
        let poll = pollFactory.makePoll(isClosed: false)
        let pollResultsVC = makePollResultsVC(for: poll)
        AssertSnapshot(pollResultsVC)
    }

    func test_appearance_whenClosed() {
        let poll = pollFactory.makePoll(isClosed: true)
        let pollResultsVC = makePollResultsVC(for: poll)
        AssertSnapshot(pollResultsVC, variants: [.defaultLight, .defaultDark])
    }

    func test_appearance_whenVotesMoreThanLimit() {
        let poll = pollFactory.makePoll(isClosed: false)
        let pollResultsVC = makePollResultsVC(for: poll)
        pollResultsVC.mockMaximumVotesPerOption = 2
        AssertSnapshot(pollResultsVC, variants: [.defaultLight, .defaultDark])
    }

    func test_appearance_whenAnonymous() {
        let poll = pollFactory.makePoll(isClosed: false, votingVisibility: .anonymous)
        let pollResultsVC = makePollResultsVC(for: poll)
        AssertSnapshot(pollResultsVC, variants: [.defaultLight])
    }

    private func makePollResultsVC(for poll: Poll) -> MockPollResultsVC {
        let mockedPollController = PollController_Mock()
        mockedPollController.mockedPoll = poll
        let pollResultsVC = MockPollResultsVC(pollController: mockedPollController)
        pollResultsVC.pollController(mockedPollController, didUpdatePoll: .create(poll))
        return pollResultsVC
    }
}

class MockPollResultsVC: PollResultsVC {
    public var mockMaximumVotesPerOption = 5

    override var maximumVotesPerOption: Int {
        mockMaximumVotesPerOption
    }
}

class PollController_Mock: PollController {
    init() {
        super.init(client: .mock, messageId: .unique, pollId: .unique)
    }

    init(client: ChatClient_Mock) {
        super.init(client: client, messageId: .unique, pollId: .unique)
    }

    var mockedPoll: Poll?
    override var poll: Poll? {
        mockedPoll
    }
}
