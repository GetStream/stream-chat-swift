//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageBubbleView_Tests: XCTestCase {
    private var bubbleContent = ChatMessageBubbleView.Content(
        backgroundColor: Appearance.default.colorPalette.background2,
        roundedCorners: CACornerMask.all.subtracting(.layerMaxXMinYCorner)
    )
    
    // MARK: - Appearance

    func test_appearance_whenNoContentSet() {
        // Create a bubble
        let bubble = ChatMessageBubbleView().withFixedSize
        
        // Set bubble content
        bubble.content = nil
        
        // Assert the bubble is rendered correctly
        AssertSnapshot(bubble, variants: .onlyUserInterfaceStyles)
    }
    
    func test_appearance_whenContentIsSet() {
        // Create a bubble
        let bubble = ChatMessageBubbleView().withFixedSize
        
        // Set bubble content
        bubble.content = bubbleContent
        
        // Assert the bubble is rendered correctly
        AssertSnapshot(bubble, variants: .onlyUserInterfaceStyles)
        
        // Assert bubble has correct values set
        XCTAssertEqual(bubble.layer.maskedCorners, bubble.content?.roundedCorners)
        XCTAssertEqual(bubble.backgroundColor, bubble.content?.backgroundColor)
    }

    func test_appearanceCustomization_usingAppearance() {
        // Create a bubble
        let bubble = ChatMessageBubbleView().withFixedSize

        // Set custom appearance
        var appearance = Appearance()
        appearance.colorPalette.border = Appearance.default.colorPalette.background4
        bubble.appearance = appearance

        // Assert the bubble is rendered correctly
        AssertSnapshot(bubble, variants: .onlyUserInterfaceStyles)
    }

    func test_appearanceCustomization_usingSubclassing() {
        // Declare custom bubble type
        class TestBubble: ChatMessageBubbleView {
            override func setUpAppearance() {
                super.setUpAppearance()
                
                layer.cornerRadius = 8
                layer.borderWidth = 4
            }
        }

        // Create a custom bubble
        let bubble = TestBubble().withFixedSize
        
        // Set bubble content
        bubble.content = bubbleContent

        // Assert the custom bubble is rendered correctly
        AssertSnapshot(bubble, variants: .onlyUserInterfaceStyles)
    }
}

private extension UIView {
    var withFixedSize: Self {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 150).isActive = true
        widthAnchor.constraint(equalToConstant: 300).isActive = true
        return self
    }
}
