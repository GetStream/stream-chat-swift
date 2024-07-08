//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

// A concrete `MessageSearchControllerDelegate` implementation allowing capturing the delegate calls
final class MessageSearchController_Delegate: QueueAwareDelegate, ChatMessageSearchControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didChangeMessages_changes: [ListChange<ChatMessage>]?
    @Atomic var didChangeMessagesExpectation: XCTestExpectation?
    @Atomic var didChangeMessagesExpectedCount = 0

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }

    func controller(
        _ controller: ChatMessageSearchController,
        didChangeMessages changes: [ListChange<ChatMessage>]
    ) {
        didChangeMessages_changes = changes
        validateQueue()
        guard let didChangeMessagesExpectation else { return }
        guard didChangeMessagesExpectedCount == controller.messages.count else { return }
        didChangeMessagesExpectation.fulfill()
    }
}
