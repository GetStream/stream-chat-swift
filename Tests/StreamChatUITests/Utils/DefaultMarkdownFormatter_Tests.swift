//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChatTestHelpers
@testable import StreamChatUI
import XCTest

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
    
    func test_containsMarkdown_whenCheckOnAStringWithNoMarkdown_thenReturnsFalse() {
        // GIVEN
        let stringWithNoMarkdown = "Hello, This is a test String"

        // WHEN
        let containsMarkdown = sut.containsMarkdown(stringWithNoMarkdown)

        // THEN
        XCTAssertEqual(false, containsMarkdown)
    }
    
    func test_containsMarkdown_whenCheckForItalicEmphasis_thenReturnsTrue() {
        // GIVEN
        let stringWithItalicMarkdown1 = "Hello, This is a *test* String"
        let stringWithItalicMarkdown2 = "Hello, This is a _test_ String"

        // WHEN
        let containsItalicMarkdown1 = sut.containsMarkdown(stringWithItalicMarkdown1)
        let containsItalicMarkdown2 = sut.containsMarkdown(stringWithItalicMarkdown2)

        // THEN
        XCTAssertEqual(true, containsItalicMarkdown1)
        XCTAssertEqual(true, containsItalicMarkdown2)
    }

    func test_containsMarkdown_whenCheckForBoldEmphasis_thenReturnsTrue() {
        // GIVEN
        let stringWithBoldMarkdown1 = "Hello, This is a **test** String"
        let stringWithBoldMarkdown2 = "Hello, This is a __test__ String"

        // WHEN
        let containsBoldMarkdown1 = sut.containsMarkdown(stringWithBoldMarkdown1)
        let containsBoldMarkdown2 = sut.containsMarkdown(stringWithBoldMarkdown2)

        // THEN
        XCTAssertEqual(true, containsBoldMarkdown1)
        XCTAssertEqual(true, containsBoldMarkdown2)
    }

    func test_containsMarkdown_whenCheckForStrikethroughEmphasis_thenReturnsTrue() {
        // GIVEN
        let stringWithStrikethroughMarkdown = "Hello, This is a ~~test~~ String"

        // WHEN
        let containsStrikethroughMarkdown = sut.containsMarkdown(stringWithStrikethroughMarkdown)

        // THEN
        XCTAssertEqual(true, containsStrikethroughMarkdown)
    }
    
    func test_containsMarkdown_whenCheckForCodeEmphasis_thenReturnsTrue() {
        // GIVEN
        let stringWithCodeMarkdown = "Hello, This is a `test` String"

        // WHEN
        let containsCodeMarkdown = sut.containsMarkdown(stringWithCodeMarkdown)

        // THEN
        XCTAssertEqual(true, containsCodeMarkdown)
    }
    
    func test_containsMarkdown_whenCheckForHeadings_thenReturnsTrue() {
        // GIVEN
        let stringWithHeadingsMarkdown1 = "# Hello, This is a test String"
        let stringWithHeadingsMarkdown2 = "###### Hello, This is a test String"
        let stringWithHeadingsMarkdown3 = """
         Hello,
         ======
         This is a test String
        """
        let stringWithHeadingsMarkdown4 = """
         Hello,
         -----
         This is a test String
        """

        // WHEN
        let containsHeadingsMarkdown1 = sut.containsMarkdown(stringWithHeadingsMarkdown1)
        let containsHeadingsMarkdown2 = sut.containsMarkdown(stringWithHeadingsMarkdown2)
        let containsHeadingsMarkdown3 = sut.containsMarkdown(stringWithHeadingsMarkdown3)
        let containsHeadingsMarkdown4 = sut.containsMarkdown(stringWithHeadingsMarkdown4)

        // THEN
        XCTAssertEqual(true, containsHeadingsMarkdown1)
        XCTAssertEqual(true, containsHeadingsMarkdown2)
        XCTAssertEqual(true, containsHeadingsMarkdown3)
        XCTAssertEqual(true, containsHeadingsMarkdown4)
    }
    
    func test_containsMarkdown_whenCheckForLinks_thenReturnsTrue() {
        // GIVEN
        let stringWithLinkMarkdown1 = "Hello, [Stream Chat](https://getstream.io/) is awesome!"
        let stringWithLinkMarkdown2 = """
           Hello, [Stream Chat][1] is awesome!
                                      
           [1]: https://getstream.io/
        """

        // WHEN
        let containsLinkMarkdown1 = sut.containsMarkdown(stringWithLinkMarkdown1)
        let containsLinkMarkdown2 = sut.containsMarkdown(stringWithLinkMarkdown2)

        // THEN
        XCTAssertEqual(true, containsLinkMarkdown1)
        XCTAssertEqual(true, containsLinkMarkdown2)
    }
    
    func test_containsMarkdown_whenCheckForBlockquotes_thenReturnsTrue() {
        // GIVEN
        let stringWithBlockquotesMarkdown = "> Hello, This is a test String"

        // WHEN
        let containsBlockquotesMarkdown = sut.containsMarkdown(stringWithBlockquotesMarkdown)

        // THEN
        XCTAssertEqual(true, containsBlockquotesMarkdown)
    }
    
    func test_containsMarkdown_whenCheckForUnorderedLists_thenReturnsTrue() {
        // GIVEN
        let stringWithUnorderedListsMarkdown = """
          - Hello,
          - This is
             - a test
                 - String
        """

        // WHEN
        let containsUnorderedListsMarkdown = sut.containsMarkdown(stringWithUnorderedListsMarkdown)

        // THEN
        XCTAssertEqual(true, containsUnorderedListsMarkdown)
    }
    
    func test_containsMarkdown_whenCheckForOrderedLists_thenReturnsTrue() {
        // GIVEN
        let stringWithOrderedListsMarkdown = """
           1. Hello,
           1. This is
               1. a test
                   1. String
        """

        // WHEN
        let containsOrderedListsMarkdown = sut.containsMarkdown(stringWithOrderedListsMarkdown)

        // THEN
        XCTAssertEqual(true, containsOrderedListsMarkdown)
    }
    
    func test_format_whenStringContainsItalicMarkdown_thenAttributedStringIncludesItalicTrait() {
        // GIVEN
        let stringWithMarkdown = "Hello, This is a *test* String"
        let expectedAttribute: UIFontDescriptor.SymbolicTraits = .traitItalic
        let expectedAttributedSubstring = "test"

        // WHEN
        let attributedString = sut.format(stringWithMarkdown)

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
        let expectedUnorderedListedSubstrings = ["・\tclass", "・\tstruct", "・\tenum", "・\tactor"]

        // WHEN
        let attributedString = sut.format(stringWithMarkdown)

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
                      fontNameAttribute == DefaultMarkdownFormatter.Attributes.Code.fontName {
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
}
