//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageBubbleView_Tests: XCTestCase {
    // MARK: - Appearance

    func test_appearance() {
        // Create a bubble
        let bubble = ChatMessageBubbleView().withFixedSize

        // Assert the bubble is rendered correctly
        AssertSnapshot(bubble, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenEphemeralMessageSentByCurrentUserLastInSequence() {
        // Create a bubble
        let bubble = ChatMessageBubbleView().withFixedSize

        // Set content with `.ephemeral` message sent by current user ending the message sequence
        bubble.content = .init(
            message: .mock(
                id: .unique,
                text: .unique,
                type: .ephemeral,
                author: .mock(id: .unique),
                isSentByCurrentUser: true
            ),
            layoutOptions: [.flipped]
        )

        // Assert the bubble is rendered correctly
        AssertSnapshot(bubble, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenEphemeralMessageSentByCurrentUserNotLastInSequence() {
        // Create a bubble
        let bubble = ChatMessageBubbleView().withFixedSize

        // Set content with `.ephemeral` message sent by current user in the middle of message sequence
        bubble.content = .init(
            message: .mock(
                id: .unique,
                text: .unique,
                type: .ephemeral,
                author: .mock(id: .unique),
                isSentByCurrentUser: true
            ),
            layoutOptions: [.continuousBubble]
        )

        // Assert the bubble is rendered correctly
        AssertSnapshot(bubble, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageSentByCurrentUserLastInSequence() {
        // Create a bubble
        let bubble = ChatMessageBubbleView().withFixedSize

        // Set content with message sent by current user ending the message sequence
        bubble.content = .init(
            message: .mock(
                id: .unique,
                text: .unique,
                author: .mock(id: .unique),
                isSentByCurrentUser: true
            ),
            layoutOptions: [.flipped]
        )

        // Assert the bubble is rendered correctly
        AssertSnapshot(bubble, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageSentByCurrentUserNotLastInSequence() {
        // Create a bubble
        let bubble = ChatMessageBubbleView().withFixedSize

        // Set content with message sent by current user in the middle of message sequence
        bubble.content = .init(
            message: .mock(
                id: .unique,
                text: .unique,
                author: .mock(id: .unique),
                isSentByCurrentUser: true
            ),
            layoutOptions: [.continuousBubble]
        )

        // Assert the bubble is rendered correctly
        AssertSnapshot(bubble, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageSentByAnotherUserLastInSequence() {
        // Create a bubble
        let bubble = ChatMessageBubbleView().withFixedSize

        // Set content with message sent by another user ending the message sequence
        bubble.content = .init(
            message: .mock(
                id: .unique,
                text: .unique,
                author: .mock(id: .unique),
                isSentByCurrentUser: false
            ),
            layoutOptions: []
        )

        // Assert the bubble is rendered correctly
        AssertSnapshot(bubble, variants: .onlyUserInterfaceStyles)
    }

    func test_appearance_whenMessageSentByAnotherUserNotLastInSequence() {
        // Create a bubble
        let bubble = ChatMessageBubbleView().withFixedSize

        // Set content with message sent by another user that is in the middle message sequence
        bubble.content = .init(
            message: .mock(
                id: .unique,
                text: .unique,
                author: .mock(id: .unique),
                isSentByCurrentUser: false
            ),
            layoutOptions: [.continuousBubble]
        )

        // Assert the bubble is rendered correctly
        AssertSnapshot(bubble, variants: .onlyUserInterfaceStyles)
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

        // Assert the custom bubble is rendered correctly
        AssertSnapshot(bubble, variants: .onlyUserInterfaceStyles)
    }

    // MARK: - Rounded corners

    func test_bubbleRoundedCorners_whenContentIsNil_returnsAll() {
        // Create a bubble without a content
        let bubble = ChatMessageBubbleView()
        bubble.content = nil
        
        // Simulate `updateContent` call
        bubble.updateContent()

        // Assert all corners are rounded
        XCTAssertEqual(bubble.layer.maskedCorners, .all)
    }

    func test_bubbleRoundedCorners_whenContinuousBubble_returnsAll() {
        // Create a bubble
        let bubble = ChatMessageBubbleView()

        // Set the content with layout options containing `.continuousBubble`
        bubble.content = .init(
            message: .mock(id: .unique, text: .unique, author: .mock(id: .unique)),
            layoutOptions: [.continuousBubble, .flipped]
        )
        
        // Simulate `updateContent` call
        bubble.updateContent()

        // Assert all corners are rounded
        XCTAssertEqual(bubble.layer.maskedCorners, .all)
    }

    func test_bubbleRoundedCorners_whenNotContinuousBubbleButFlipped_roundsBottomRightCorner() {
        // Create a bubble
        let bubble = ChatMessageBubbleView()

        // Set the content with layout options without `.continuousBubble` but with `.flipped` option
        bubble.content = .init(
            message: .mock(id: .unique, text: .unique, author: .mock(id: .unique)),
            layoutOptions: [.flipped]
        )
        
        // Simulate `updateContent` call
        bubble.updateContent()

        // Assert all corners are rounded but bottom right
        XCTAssertEqual(bubble.layer.maskedCorners, CACornerMask.all.subtracting(.layerMaxXMaxYCorner))
    }

    func test_bubbleRoundedCorners_whenNorContinuousBubbleNorFlipped_roundsBottomLeftCorner() {
        // Create a bubble
        let bubble = ChatMessageBubbleView()

        // Set the content with layout options without `.continuousBubble` and `.flipped` options
        bubble.content = .init(
            message: .mock(id: .unique, text: .unique, author: .mock(id: .unique)),
            layoutOptions: []
        )
        
        // Simulate `updateContent` call
        bubble.updateContent()

        // Assert all corners are rounded but bottom left
        XCTAssertEqual(bubble.layer.maskedCorners, CACornerMask.all.subtracting(.layerMinXMaxYCorner))
    }

    // MARK: - Background

    func test_bubbleBackgroundColor_whenContentIsNil_returnsClear() {
        // Create a bubble
        let bubble = ChatMessageBubbleView()
        
        // Reset the content
        bubble.content = nil
        
        // Simulate `updateContent` call
        bubble.updateContent()

        // Assert `.clear` color is returned
        XCTAssertEqual(bubble.backgroundColor, .clear)
    }

    func test_bubbleBackgroundColor_whenEphemeralMessage_returnsPopoverBackground() {
        // Create a bubble
        let bubble = ChatMessageBubbleView()

        // Set the content with `.ephemeral` message
        bubble.content = .init(
            message: .mock(
                id: .unique,
                text: .unique,
                type: .ephemeral,
                author: .mock(id: .unique)
            ),
            layoutOptions: []
        )
        
        // Simulate `updateContent` call
        bubble.updateContent()

        // Assert correct color is returned
        XCTAssertEqual(bubble.backgroundColor, bubble.appearance.colorPalette.popoverBackground)
    }

    func test_bubbleBackgroundColor_whenMessageIsSentByCurrentUser_returnsBackground6() {
        // Create a bubble
        let bubble = ChatMessageBubbleView()

        // Set the content with non-ephemeral message sent by current user
        bubble.content = .init(
            message: .mock(
                id: .unique,
                text: .unique,
                author: .mock(id: .unique),
                isSentByCurrentUser: true
            ),
            layoutOptions: []
        )
        
        // Simulate `updateContent` call
        bubble.updateContent()

        // Assert correct color is returned
        XCTAssertEqual(bubble.backgroundColor, bubble.appearance.colorPalette.background6)
    }

    func test_bubbleBackgroundColor_whenMessageIsSentNotByCurrentUser_returnsPopoverBackground() {
        // Create a bubble
        let bubble = ChatMessageBubbleView()

        // Set the content with non-ephemeral message sent by another user
        bubble.content = .init(
            message: .mock(
                id: .unique,
                text: .unique,
                author: .mock(id: .unique),
                isSentByCurrentUser: false
            ),
            layoutOptions: []
        )
        
        // Simulate `updateContent` call
        bubble.updateContent()

        // Assert correct color is returned
        XCTAssertEqual(bubble.backgroundColor, bubble.appearance.colorPalette.popoverBackground)
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
