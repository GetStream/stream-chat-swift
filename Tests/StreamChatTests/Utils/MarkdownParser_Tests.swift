//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

// Note: Snapshot tests are in ChatMessageMarkdown_Tests

@available(iOS 15, *)
final class MarkdownParser_Tests: XCTestCase {
    private var parser: MarkdownParser!
    
    override func setUpWithError() throws {
        parser = MarkdownParser()
    }
    
    override func tearDownWithError() throws {
        parser = nil
    }
    
    func test_containsMarkdown_whenCheckOnAStringWithNoMarkdown_thenReturnsFalse() {
        let stringWithNoMarkdown = "Hello, This is a test String"
        let containsMarkdown = parser.containsMarkdown(stringWithNoMarkdown)
        XCTAssertEqual(false, containsMarkdown)
    }

    func test_containsMarkdown_whenCheckForItalicEmphasis_thenReturnsTrue() {
        let stringWithItalicMarkdown1 = "Hello, This is a *test* String"
        let stringWithItalicMarkdown2 = "Hello, This is a _test_ String"
        let containsItalicMarkdown1 = parser.containsMarkdown(stringWithItalicMarkdown1)
        let containsItalicMarkdown2 = parser.containsMarkdown(stringWithItalicMarkdown2)
        XCTAssertEqual(true, containsItalicMarkdown1)
        XCTAssertEqual(true, containsItalicMarkdown2)
    }

    func test_containsMarkdown_whenCheckForBoldEmphasis_thenReturnsTrue() {
        let stringWithBoldMarkdown1 = "Hello, This is a **test** String"
        let stringWithBoldMarkdown2 = "Hello, This is a __test__ String"
        let containsBoldMarkdown1 = parser.containsMarkdown(stringWithBoldMarkdown1)
        let containsBoldMarkdown2 = parser.containsMarkdown(stringWithBoldMarkdown2)
        XCTAssertEqual(true, containsBoldMarkdown1)
        XCTAssertEqual(true, containsBoldMarkdown2)
    }

    func test_containsMarkdown_whenCheckForStrikethroughEmphasis_thenReturnsTrue() {
        let stringWithStrikethroughMarkdown = "Hello, This is a ~~test~~ String"
        let containsStrikethroughMarkdown = parser.containsMarkdown(stringWithStrikethroughMarkdown)
        XCTAssertEqual(true, containsStrikethroughMarkdown)
    }

    func test_containsMarkdown_whenCheckForCodeEmphasis_thenReturnsTrue() {
        let stringWithCodeMarkdown = "Hello, This is a `test` String"
        let containsCodeMarkdown = parser.containsMarkdown(stringWithCodeMarkdown)
        XCTAssertEqual(true, containsCodeMarkdown)
    }

    func test_containsMarkdown_whenCheckForHeadings_thenReturnsTrue() {
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
        let containsHeadingsMarkdown1 = parser.containsMarkdown(stringWithHeadingsMarkdown1)
        let containsHeadingsMarkdown2 = parser.containsMarkdown(stringWithHeadingsMarkdown2)
        let containsHeadingsMarkdown3 = parser.containsMarkdown(stringWithHeadingsMarkdown3)
        let containsHeadingsMarkdown4 = parser.containsMarkdown(stringWithHeadingsMarkdown4)
        XCTAssertEqual(true, containsHeadingsMarkdown1)
        XCTAssertEqual(true, containsHeadingsMarkdown2)
        XCTAssertEqual(true, containsHeadingsMarkdown3)
        XCTAssertEqual(true, containsHeadingsMarkdown4)
    }

    func test_containsMarkdown_whenCheckForLinks_thenReturnsTrue() {
        let stringWithLinkMarkdown1 = "Hello, [Stream Chat](https://getstream.io/) is awesome!"
        let stringWithLinkMarkdown2 = """
           Hello, [Stream Chat][1] is awesome!

           [1]: https://getstream.io/
        """
        let containsLinkMarkdown1 = parser.containsMarkdown(stringWithLinkMarkdown1)
        let containsLinkMarkdown2 = parser.containsMarkdown(stringWithLinkMarkdown2)
        XCTAssertEqual(true, containsLinkMarkdown1)
        XCTAssertEqual(true, containsLinkMarkdown2)
    }

    func test_containsMarkdown_whenCheckForBlockquotes_thenReturnsTrue() {
        let stringWithBlockquotesMarkdown = "> Hello, This is a test String"
        let containsBlockquotesMarkdown = parser.containsMarkdown(stringWithBlockquotesMarkdown)
        XCTAssertEqual(true, containsBlockquotesMarkdown)
    }

    func test_containsMarkdown_whenCheckForUnorderedLists_thenReturnsTrue() {
        let stringWithUnorderedListsMarkdown = """
          - Hello,
          - This is
             - a test
                 - String
        """
        let containsUnorderedListsMarkdown = parser.containsMarkdown(stringWithUnorderedListsMarkdown)
        XCTAssertEqual(true, containsUnorderedListsMarkdown)
    }

    func test_containsMarkdown_whenCheckForOrderedLists_thenReturnsTrue() {
        let stringWithOrderedListsMarkdown = """
           1. Hello,
           1. This is
               1. a test
                   1. String
        """
        let containsOrderedListsMarkdown = parser.containsMarkdown(stringWithOrderedListsMarkdown)
        XCTAssertEqual(true, containsOrderedListsMarkdown)
    }
    
    func test_style_detectPresentationIntents() throws {
        let markdown = """
        # H1  
        - Unordered 1
        - Unordered 2
            - Unordered _nested_
        
        ## H2  
        1. Ordered **1**
        2. Ordered 2
            1. Ordered nested
        
        Text
        
        ### H3  
        > Text that is a quote
        
        #### H4  
        ```swift
        Code block
        ```
        ##### H5
        ###### H6
        """
        let expectedPresentationKinds = Set<PresentationIntent.Kind>([
            .blockQuote,
            .codeBlock(languageHint: "swift"),
            .header(level: 1),
            .header(level: 2),
            .header(level: 3),
            .header(level: 4),
            .header(level: 5),
            .header(level: 6),
            .listItem(ordinal: 1),
            .listItem(ordinal: 2)
        ])
        let expectedInlinePresentationIntents = Set<InlinePresentationIntent>([
            .emphasized, .stronglyEmphasized
        ])
        var parsedPresentationKinds = Set<PresentationIntent.Kind>()
        var parsedInlinePresentationKinds = Set<InlinePresentationIntent>()
        let parser = MarkdownParser()
        _ = try parser.style(
            markdown: markdown,
            options: .init(layoutDirectionLeftToRight: true),
            attributes: AttributeContainer(),
            inlinePresentationIntentAttributes: { intent in
                parsedInlinePresentationKinds.insert(intent)
                return nil
            },
            presentationIntentAttributes: { kind, _ in
                parsedPresentationKinds.insert(kind)
                return nil
            }
        )
        XCTAssertEqual(expectedInlinePresentationIntents, parsedInlinePresentationKinds)
        XCTAssertEqual(expectedPresentationKinds, parsedPresentationKinds)
    }
}
