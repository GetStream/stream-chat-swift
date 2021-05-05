//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class CreateChatChannelButton_Tests: XCTestCase {
    func test_defaultAppearance() {
        let view = CreateChatChannelButton().withoutAutoresizingMaskConstraints
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_isHighlighted() {
        let view = CreateChatChannelButton().withoutAutoresizingMaskConstraints
        view.isHighlighted = true
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_isDisabled() {
        let view = CreateChatChannelButton().withoutAutoresizingMaskConstraints
        view.isEnabled = false
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_customizationUsingAppearance() {
        var appearance = Appearance()
        appearance.images.newChannel = appearance.images.close

        let view = CreateChatChannelButton().withoutAutoresizingMaskConstraints
        view.appearance = appearance
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
}
