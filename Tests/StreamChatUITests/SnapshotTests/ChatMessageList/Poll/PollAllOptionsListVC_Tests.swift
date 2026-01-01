//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import UIKit
import XCTest

final class PollAllOptionsListVC_Tests: XCTestCase {
    let currentUser = ChatUser.mock(
        id: .unique,
        name: "José Mourinho"
    )

    lazy var pollFactory = PollMockFactory(currentUser: currentUser)

    func test_appearance() {
        let poll = pollFactory.makePoll(isClosed: false)
        let pollController = PollController_Mock()
        pollController.mockedPoll = poll
        let pollAllOptionsListVC = PollAllOptionsListVC(pollController: pollController)
        AssertSnapshot(pollAllOptionsListVC)
    }

    func test_appearance_whenIsClosed() {
        let poll = pollFactory.makePoll(isClosed: true)
        let pollController = PollController_Mock()
        pollController.mockedPoll = poll
        let pollAllOptionsListVC = PollAllOptionsListVC(pollController: pollController)
        AssertSnapshot(pollAllOptionsListVC)
    }
}
