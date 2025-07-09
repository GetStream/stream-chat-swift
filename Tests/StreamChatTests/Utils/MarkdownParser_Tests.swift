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
    
    func test_style_text() throws {
        let text = "This is some text"
        var didStyle = false
        let result = try parser.style(
            markdown: text,
            options: MarkdownParser.ParsingOptions(),
            attributes: AttributeContainer(),
            inlinePresentationIntentAttributes: { _ in
                didStyle = true
                return nil
            },
            presentationIntentAttributes: { _, _ in
                didStyle = true
                return nil
            }
        )
        XCTAssertEqual(false, didStyle)
        XCTAssertEqual(text, String(result.characters))
    }
    
    func test_style_textWithNewlines() throws {
        let text = """
        This is the first line
        
        
        This is the fourth line
        """
        var didStyle = false
        let result = try parser.style(
            markdown: text,
            options: MarkdownParser.ParsingOptions(),
            attributes: AttributeContainer(),
            inlinePresentationIntentAttributes: { _ in
                didStyle = true
                return nil
            },
            presentationIntentAttributes: { _, _ in
                didStyle = true
                return nil
            }
        )
        XCTAssertEqual(false, didStyle)
        XCTAssertEqual(text, String(result.characters))
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
    
    func test_style_fixLinksWithoutSchemeAndHost() throws {
        let markdown = """
        [link](getstream.io)
        [link](https://example.com)
        [link](https://getstream.io/chat/)
        """
        let string = try MarkdownParser().style(
            markdown: markdown,
            options: MarkdownParser.ParsingOptions(),
            attributes: AttributeContainer(),
            inlinePresentationIntentAttributes: { _ in nil },
            presentationIntentAttributes: { _, _ in nil }
        )
        let expected = [
            "https://getstream.io",
            "https://example.com",
            "https://getstream.io/chat/"
        ]
        let result = string.runs[\.link].compactMap { $0.0?.absoluteString }
        XCTAssertEqual(expected, result)
    }
}
