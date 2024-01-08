//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class MessageActionsTransitionController_Tests: XCTestCase {
    private lazy var subject: ChatMessageActionsTransitionController! = .init(messageListVC: nil)

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - makeMessageContentView(fromOriginalView:)

    func test_makeMessageContentView_delegateWasSetToOriginalViewDelegate() {
        let originalView = ChatMessageContentView()
        let delegate = ChatMessageContentViewDelegate_Mock()
        originalView.delegate = delegate

        let newMessageContentView = subject.makeMessageContentView(fromOriginalView: originalView)

        XCTAssertTrue(newMessageContentView.delegate === delegate)
    }
}
