//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
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
        let expectedUnorderedListedSubstrings = ["\u{2022}  class", "\u{2022}  struct", "\u{2022}  enum", "\u{2022}  actor"]

        // WHEN
        let attributedString = sut.format(stringWithMarkdown, attributes: [:])

        // THEN
        attributedString.enumerateAttributes(in: NSRange(
            location: 0,
            length: attributedString.length
        )) { attributes, range, _ in
            let fontAttribute = attributes[.font] as? UIFont

            if let headerAttribute = fontAttribute,
               headerAttribute.fontDescriptor.pointSize == UIFont.preferredFont(forTextStyle: .title1).pointSize {
                XCTAssertEqual(expectedHeading1AttributedSubstring, attributedString.attributedSubstring(from: range).string)
            } else if let strikethroughAttribute = attributes[.strikethroughStyle] as? NSNumber,
                      strikethroughAttribute == 1 {
                XCTAssertEqual(expectedStrikethroughAttributedSubstring, attributedString.attributedSubstring(from: range).string)
            } else if let boldAttribute = fontAttribute,
                      boldAttribute.fontDescriptor.symbolicTraits.contains(.traitBold) {
                XCTAssertEqual(expectedBoldAttributedSubstring, attributedString.attributedSubstring(from: range).string)
            } else if let fontAttribute = fontAttribute,
                      let fontNameAttribute = fontAttribute.fontDescriptor.fontAttributes[.name] as? String,
                      fontNameAttribute == DefaultMarkdownFormatter().styles.codeFont.name {
                XCTAssertEqual(expectedCodeAttributedSubstring, attributedString.attributedSubstring(from: range).string)
            } else if let linkAttribute = attributes[.link] as? NSURL,
                      let url = linkAttribute.absoluteString {
                XCTAssertEqual(expectedLinkAttributedSubstring, attributedString.attributedSubstring(from: range).string)
                XCTAssertEqual(expectedLinkURL, url)
            } else if let paragraphStyleAttribute = attributes[.paragraphStyle] as? NSParagraphStyle,
                      paragraphStyleAttribute.headIndent > 0 {
                XCTAssertEqual(
                    true,
                    expectedUnorderedListedSubstrings.contains(attributedString.attributedSubstring(from: range).string)
                )
            }
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
