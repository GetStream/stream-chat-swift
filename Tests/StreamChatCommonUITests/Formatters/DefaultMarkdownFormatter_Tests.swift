//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChatCommonUI
import StreamSwiftTestHelpers
import XCTest

// Note: Snapshot tests are in ChatMessageMarkdown_Tests

final class DefaultMarkdownFormatter_Tests: XCTestCase {
    var sut: DefaultMarkdownFormatter!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = DefaultMarkdownFormatter()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func test_format_whenStringContainsItalicMarkdown_thenAttributedStringIncludesItalicTrait() {
        // GIVEN
        let stringWithMarkdown = "Hello, This is a *test* String"
        let expectedAttribute: UIFontDescriptor.SymbolicTraits = .traitItalic
        let expectedAttributedSubstring = "test"

        // WHEN
        let attributedString = sut.format(stringWithMarkdown, attributes: [:])

        // THEN
        attributedString.enumerateAttribute(.font, in: NSRange(location: 0, length: attributedString.length)) { value, range, _ in
            if let font = value as? UIFont, font.fontDescriptor.symbolicTraits.contains(expectedAttribute) {
                XCTAssertEqual(expectedAttributedSubstring, attributedString.attributedSubstring(from: range).string)
            }
        }
    }

    func test_format_whenStringContainsManyMarkdowns_thenAttributedStringIncludesAllAttibutes() {
        // GIVEN
        let stringWithMarkdown =
            """
            # Swift

            Swift is a new ~~programming~~ language for iOS, macOS, watchOS, and tvOS **app development**. Here is an example of its syntax:

            `let property: Double = 10.0`

            Swift has different keywords for defining types such as:
            - class
            - struct
            - enum
            - actor

            For more information you can visit [this link](https://docs.swift.org/swift-book/).
            """

        let expectedHeading1AttributedSubstring = "Swift"
        let expectedStrikethroughAttributedSubstring = "programming"
        let expectedBoldAttributedSubstring = "app development"
        let expectedCodeAttributedSubstring = "let property: Double = 10.0"
        let expectedLinkAttributedSubstring = "this link"
        let expectedLinkURL = "https://docs.swift.org/swift-book/"
        let expectedListItems = ["class", "struct", "enum", "actor"]

        // WHEN
        let attributedString = sut.format(stringWithMarkdown, attributes: [:])

        // THEN
        var listItemBuffer = ""
        var currentHeadIndent: CGFloat?

        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length)) { attributes, range, _ in
            let substring = attributedString.attributedSubstring(from: range).string
            let fontAttribute = attributes[.font] as? UIFont

            // Heading 1 check
            if let headerAttribute = fontAttribute,
               headerAttribute.fontDescriptor.pointSize == UIFont.preferredFont(forTextStyle: .title1).pointSize {
                XCTAssertEqual(expectedHeading1AttributedSubstring, substring)

                // Strikethrough check
            } else if let strikethroughAttribute = attributes[.strikethroughStyle] as? NSNumber,
                      strikethroughAttribute == 1 {
                XCTAssertEqual(expectedStrikethroughAttributedSubstring, substring)

                // Bold check
            } else if let boldAttribute = fontAttribute,
                      boldAttribute.fontDescriptor.symbolicTraits.contains(.traitBold) {
                XCTAssertEqual(expectedBoldAttributedSubstring, substring)

                // Code font check
            } else if let fontAttribute = fontAttribute,
                      let fontNameAttribute = fontAttribute.fontDescriptor.fontAttributes[.name] as? String,
                      fontNameAttribute == DefaultMarkdownFormatter().styles.codeFont.name {
                XCTAssertEqual(expectedCodeAttributedSubstring, substring)

                // Link check
            } else if let linkAttribute = attributes[.link] as? NSURL,
                      let url = linkAttribute.absoluteString {
                XCTAssertEqual(expectedLinkAttributedSubstring, substring)
                XCTAssertEqual(expectedLinkURL, url)
            }

            // List item handling
            if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle,
               paragraphStyle.headIndent > 0 {
                // same list item as previous?
                if currentHeadIndent == paragraphStyle.headIndent {
                    listItemBuffer += substring
                } else {
                    // process previous buffer
                    if !listItemBuffer.isEmpty {
                        XCTAssertTrue(expectedListItems.contains { listItemBuffer.contains($0) })
                    }
                    // start new buffer
                    listItemBuffer = substring
                    currentHeadIndent = paragraphStyle.headIndent
                }
            } else {
                // process any leftover buffer
                if !listItemBuffer.isEmpty {
                    XCTAssertTrue(expectedListItems.contains { listItemBuffer.contains($0) })
                    listItemBuffer = ""
                    currentHeadIndent = nil
                }
            }
        }

        // process last buffer
        if !listItemBuffer.isEmpty {
            XCTAssertTrue(expectedListItems.contains { listItemBuffer.contains($0) })
        }
    }

    func test_complexMarkdownPattern_doesNotHangForever() {
        let string = "**~*~~~*~*~**~*~* h e a r d ***~*~*~**~*~~~*"
        let expected = "~~~*~** h e a r d ~~~*~~~~"
        let result = sut.format(string, attributes: [:])
        XCTAssertEqual(expected, result.string)
    }
    
    func test_thematicBreak_isHandled() {
        let string = """
        ---
        hi!
        """
        let expected = """
        ⸻
        hi!
        """
        let result = sut.format(string, attributes: [:])
        XCTAssertEqual(expected, result.string)
    }
}
