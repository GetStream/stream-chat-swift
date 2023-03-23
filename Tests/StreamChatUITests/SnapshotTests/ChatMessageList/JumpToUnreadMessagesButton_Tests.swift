//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class JumpToUnreadMessagesButtonTests: XCTestCase {
    func test_jumpToUnreadMessages_zeroMessages() {
        let button = JumpToUnreadMessagesButton()
        button.content = 0
        button.translatesAutoresizingMaskIntoConstraints = false
        button.sizeToFit()

        AssertSnapshot(button, variants: [.defaultDark, .defaultLight], record: true)
    }
}
