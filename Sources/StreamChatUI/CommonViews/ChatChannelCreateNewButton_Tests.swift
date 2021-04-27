//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatChannelCreateNewButton_Tests: XCTestCase {
    func test_defaultAppearance() {
        let view = ChatChannelCreateNewButton().withoutAutoresizingMaskConstraints
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_isHighlighted() {
        let view = ChatChannelCreateNewButton().withoutAutoresizingMaskConstraints
        view.isHighlighted = true
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_isDisabled() {
        let view = ChatChannelCreateNewButton().withoutAutoresizingMaskConstraints
        view.isEnabled = false
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_customizationUsingAppearance() {
        var appearance = Appearance()
        appearance.images.newChat = appearance.images.close

        let view = ChatChannelCreateNewButton().withoutAutoresizingMaskConstraints
        view.appearance = appearance
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
}
