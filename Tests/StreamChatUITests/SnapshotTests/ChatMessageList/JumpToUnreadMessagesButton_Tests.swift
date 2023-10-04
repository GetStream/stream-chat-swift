//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatTestHelpers
@testable import StreamChatUI
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
