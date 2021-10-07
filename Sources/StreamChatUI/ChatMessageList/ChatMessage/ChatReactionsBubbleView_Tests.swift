//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatReactionsBubbleView_Tests: XCTestCase {
    func test_defaultAppearance_toLeadingTail() {
        // Create a bubble
        let bubble = ChatReactionsBubbleView().withFixedSize
        
        // Set bubble content
        bubble.tailDirection = .toLeading
        
        // Assert the bubble is rendered correctly
        AssertSnapshot(bubble, variants: .onlyUserInterfaceStyles)
    }
    
    func test_defaultAppearance_toTrailingTail() {
        // Create a bubble
        let bubble = ChatReactionsBubbleView().withFixedSize
        
        // Set bubble content
        bubble.tailDirection = .toTrailing
        
        // Assert the bubble is rendered correctly
        AssertSnapshot(bubble, variants: .onlyUserInterfaceStyles)
    }

    func test_appearanceCustomization_usingAppearance() {
        // Create a bubble
        let bubble = ChatReactionsBubbleView().withFixedSize

        // Set custom appearance
        var appearance = Appearance()
        appearance.colorPalette.border = Appearance.default.colorPalette.alert
        bubble.appearance = appearance

        // Assert the bubble is rendered correctly
        AssertSnapshot(bubble, variants: .onlyUserInterfaceStyles)
    }

    func test_appearanceCustomization_usingSubclassing() {
        // Declare custom bubble type
        class TestBubble: ChatReactionsBubbleView {
            override var fillColor: UIColor? {
                appearance.colorPalette.background2
            }

            override var strokeColor: UIColor? {
                appearance.colorPalette.alternativeActiveTint
            }
        }

        // Create a custom bubble
        let bubble = TestBubble().withFixedSize
        
        // Set tail direction
        bubble.tailDirection = .toLeading

        // Assert the custom bubble is rendered correctly
        AssertSnapshot(bubble, variants: .onlyUserInterfaceStyles)
    }
}

private extension UIView {
    var withFixedSize: Self {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 40).isActive = true
        widthAnchor.constraint(equalToConstant: 100).isActive = true
        return self
    }
}
