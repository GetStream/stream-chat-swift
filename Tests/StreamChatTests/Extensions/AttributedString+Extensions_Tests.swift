//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

// Note: Snapshot tests are in ChatMessageMarkdown_Tests

@available(iOS 15, *)
final class AttributedStringExtensions_Tests: XCTestCase {
    func test_markdown_detectPresentationIntents() throws {
        let markdown = """
        # H1  
        - Unordered 1
        - Unordered 2
            - Unordered nested
        
        ## H2  
        1. Ordered 1
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
        let expected = Set<PresentationIntent.Kind>([
            .blockQuote,
            .codeBlock(languageHint: "swift"),
            .header(level: 1),
            .header(level: 2),
            .header(level: 3),
            .header(level: 4),
            .header(level: 5),
            .header(level: 6)
        ])
        var parsedPresentationKinds = Set<PresentationIntent.Kind>()
        _ = try AttributedString(markdown: markdown, attributes: AttributeContainer()) { kind, _ in
            parsedPresentationKinds.insert(kind)
            return AttributeContainer()
        }
        XCTAssertEqual(expected, parsedPresentationKinds)
    }
}
