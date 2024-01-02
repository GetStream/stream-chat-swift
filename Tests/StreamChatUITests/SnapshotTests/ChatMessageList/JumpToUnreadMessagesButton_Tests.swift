//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class JumpToUnreadMessagesButtonTests: XCTestCase {
    func test_jumpToUnreadMessages_zeroMessages() {
        let button = JumpToUnreadMessagesButton()
        button.content = .noUnread
        button.translatesAutoresizingMaskIntoConstraints = false
        button.sizeToFit()

        AssertSnapshot(button, variants: [.defaultDark, .defaultLight])
    }

    func test_jumpToUnreadMessages_hundredMessages() {
        let button = JumpToUnreadMessagesButton()
        button.content = .mock(messages: 100)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.sizeToFit()

        AssertSnapshot(button, variants: [.defaultDark, .defaultLight])
    }
}
