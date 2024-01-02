//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageListDateSeparatorView_Tests: XCTestCase {
    private lazy var subject: ChatMessageListDateSeparatorView! = .init()

    override func tearDownWithError() throws {
        subject = nil
        try super.tearDownWithError()
    }

    // MARK: - setUpLayout

    func test_setUpLayout_subviewsHaveBeenConfiguredCorrectly() {
        subject.setUpLayout()

        XCTAssertEqual(subject.subviews.count, 1)
        XCTAssertEqual(subject.subviews.first, subject.container)
        XCTAssertEqual(subject.container.subviews.count, 1)
        XCTAssertEqual(subject.container.subviews.first, subject.textLabel)
    }

    // MARK: - setUpAppearance

    func test_setUpAppearance_subviewsHaveBeenConfiguredCorrectly() {
        subject.setUpAppearance()

        XCTAssertNil(subject.backgroundColor)
        XCTAssertEqual(subject.container.backgroundColor, subject.appearance.colorPalette.background7)
        XCTAssertEqual(subject.textLabel.font, subject.appearance.fonts.footnote)
        XCTAssertEqual(subject.textLabel.textColor, subject.appearance.colorPalette.staticColorText)
    }

    // MARK: - updateContent

    func test_updateContent_contentTextLabelWasUpdatedCorrectly() {
        let expected = "StreamChatUI test"
        subject.content = expected

        subject.updateContent()

        XCTAssertEqual(subject.textLabel.text, expected)
    }

    // MARK: - layoutSubviews

    func test_layoutSubviews_contentTextLabelWasUpdatedCorrectly() {
        let expected = "StreamChatUI test"
        subject.content = expected
        subject.setUpLayout()
        subject.updateContent()
        subject.frame = .init(x: 0, y: 0, width: 100, height: 150)

        subject.setNeedsLayout()
        subject.layoutIfNeeded()

        XCTAssertEqual(subject.container.layer.cornerRadius, 75)
    }
}
