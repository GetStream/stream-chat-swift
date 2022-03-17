//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageErrorIndicator_Tests: XCTestCase {
    func test_appearanceCustomization_usingAppearance() {
        // Create custom appearance
        var appearance = Appearance()
        appearance.colorPalette.alert = Appearance.default.colorPalette.highlightedAccentBackground1

        // Create an error indicator
        let errorIndicator = ChatMessageErrorIndicator().withoutAutoresizingMaskConstraints

        // Inject the custom appearance
        errorIndicator.appearance = appearance

        // Assert the indicator is rendered correctly
        AssertSnapshot(errorIndicator, variants: .onlyUserInterfaceStyles)
    }

    func test_appearanceCustomization_usingSubclassing() {
        // Declare custom subclass
        class TestErrorIndicator: ChatMessageErrorIndicator {
            override func setUpAppearance() {
                setImage(appearance.images.close, for: .normal)
                tintColor = appearance.colorPalette.highlightedAccentBackground1
            }
        }

        // Create an error indicator
        let errorIndicator = TestErrorIndicator().withoutAutoresizingMaskConstraints

        // Assert the indicator is rendered correctly
        AssertSnapshot(errorIndicator, variants: .onlyUserInterfaceStyles)
    }
}
