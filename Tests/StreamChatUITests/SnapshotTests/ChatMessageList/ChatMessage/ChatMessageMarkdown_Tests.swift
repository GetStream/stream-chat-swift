//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

@MainActor final class ChatMessageMarkdown_Tests: XCTestCase {
    override func tearDownWithError() throws {
        Appearance.default = Appearance()
    }
    
    func test_text() {
        let view = contentView(
            """
            This is **bold** text  
            This text is _italicized_  
            This was ~~mistaken~~ text  
            This has backslashes for a newline\\
            This has html line break<br/>Will span two lines
            """
        )
        AssertSnapshot(view)
    }
    
    func test_text_custom() {
        var styles = MarkdownStyles()
        styles.bodyFont.color = .systemOrange
        let view = contentView(
            styles: styles,
            """
            This is **bold** text  
            This text is _italicized_  
            This was ~~mistaken~~ text  
            This has backslashes for a newline\\
            This has html line break<br/>Will span two lines
            """
        )
        AssertSnapshot(view)
    }
    
    func test_headers() {
        let view = contentView(
            """
            # A first level heading
            ## A _second_ level heading
            ### A `third` level heading
            #### A ~fourth~ level heading
            ##### A fifth level heading
            ###### A sixth level heading
            """
        )
        AssertSnapshot(view)
    }
    
    func test_headers_custom() {
        var styles = MarkdownStyles()
        styles.h1Font.color = .systemRed
        styles.h1Font.size = 40
        styles.h2Font.color = .systemGreen
        styles.h2Font.name = "Helvetica"
        styles.h3Font.color = .systemBlue
        styles.h3Font.styling = .boldItalic
        styles.h4Font.color = .systemPink
        styles.h4Font.styling = .normal
        styles.h5Font.color = .systemTeal
        styles.h5Font.styling = .italic
        styles.h6Font.color = .systemBrown
        let view = contentView(
            styles: styles,
            """
            # A first level heading
            ## A _second_ level heading
            ### A `third` level heading
            #### A ~fourth~ level heading
            ##### A fifth level heading
            ###### A sixth level heading
            """
        )
        AssertSnapshot(view)
    }
    
    func test_headers_appearance_scaled_font() {
        Appearance.default.fonts.title = UIFontMetrics.default.scaledFont(for: Appearance.default.fonts.title)
        Appearance.default.fonts.title2 = UIFontMetrics.default.scaledFont(for: Appearance.default.fonts.title2)
        Appearance.default.fonts.title3 = UIFontMetrics.default.scaledFont(for: Appearance.default.fonts.title3)
        Appearance.default.fonts.headline = UIFontMetrics.default.scaledFont(for: Appearance.default.fonts.headline)
        Appearance.default.fonts.subheadline = UIFontMetrics.default.scaledFont(for: Appearance.default.fonts.subheadline)
        Appearance.default.fonts.footnote = UIFontMetrics.default.scaledFont(for: Appearance.default.fonts.footnote)
        let view = contentView(
            """
            # A first level heading
            ## A _second_ level heading
            ### A `third` level heading
            #### A ~fourth~ level heading
            ##### A fifth level heading
            ###### A sixth level heading
            """
        )
        AssertSnapshot(view)
    }
    
    func test_unorderedLists() {
        let view = contentView(
            """
            Unordered (no nesting)
            
            Fruits:
            - **Oranges** (bold)
            - Apples

            Trees:
            * Birch
            * Maple

            Animals:
            + Cat
            + _Dog_ (italic)
            + Rabbit
            """
        )
        AssertSnapshot(view)
    }
    
    func test_unorderedLists_nested() {
        let view = contentView(
            """
            Unordered (nested)  
            - First list item
                - First nested
                    - Second nested
            """
        )
        AssertSnapshot(view)
    }
    
    func test_orderedList_nested_wrappedTextItem() {
        let view = contentView(
            """
            Unordered (wrapped text)  
            - First list item which has a very long text and when wrapped, should be aligned to the same item
                - First nested which has a very long text and when wrapped, should be aligned to the same item
                    - Second nested
            """
        )
        AssertSnapshot(view)
    }
    
    func test_orderedLists() {
        let view = contentView(
            """
            Ordered (no nesting)
            
            Fruits:
            1. **Oranges** (bold)
            1. Apples
            
            Animals:
            1. Cat
            2. _Dog_ (italic)
            3. Rabbit
            """
        )
        AssertSnapshot(view)
    }
    
    func test_orderedLists_nested() {
        let view = contentView(
            """
            Unordered (nested)  
            1. First list item
                1. First nested
                    1. Second nested
                    2. Second nested (2)
            """
        )
        AssertSnapshot(view)
    }
    
    func test_mixedLists_nested() {
        let view = contentView(
            """
            Mixed (nested)  
            1. First list item
                - First nested
                    1. Second nested
                    2. Second nested (2)
            """
        )
        AssertSnapshot(view)
    }
    
    func test_links() {
        let view = contentView(
            """
            This site is cool: [Stream](https://getstream.io/)
            - *Hey*
                - This [link](https://getstream.io/) is in a list
            """
        )
        AssertSnapshot(view)
    }
    
    func test_code() {
        let view = contentView(
            """
            This is inline code: `git init`
            
            ### `Inline` in header
            
            Git commands:
            ```
            git status
            git add
            git commit
            ```
            
            Swift:
            ```swift
            func formatted() -> AttributedString {
                // TODO: Implement markdown formatting
            }
            ```
            """
        )
        AssertSnapshot(view)
    }
    
    func test_code_inlineOnMultipleLines() {
        let view = contentView(
            """
            `inline code`
            
            `inline code which
            should render on a single line`
            """
        )
        AssertSnapshot(view)
    }
    
    func test_code_singleBlock() {
        let view = contentView(
            """
            ```
            No newlines above and below
            ```
            """
        )
        AssertSnapshot(view)
    }
    
    func test_code_custom() {
        var styles = MarkdownStyles()
        styles.codeFont.color = .systemRed
        styles.codeFont.size = 12
        let view = contentView(
            styles: styles,
            """
            Custom: font `12`, color `red`
            
            This is inline code: `git init`
            
            ### `Inline` in header
            
            Git commands:
            ```
            git status
            git add
            git commit
            ```
            
            Swift:
            ```swift
            func formatted() -> AttributedString {
                // TODO: Implement markdown formatting
            }
            ```
            """
        )
        AssertSnapshot(view)
    }
    
    func test_quote() {
        let view = contentView(
            """
            Text that is not a quote
            > Text that is a quote
            """
        )
        AssertSnapshot(view)
    }
    
    func test_quote_multipleLines() {
        let view = contentView(
            """
            Text that is not a quote
            > Quote
            > should
            > render
            > on
            > a
            > single
            > line
            """
        )
        AssertSnapshot(view)
    }
    
    func test_quote_separate() {
        let view = contentView(
            """
            Text that is not a quote
            > Text that is a quote
            
            > This is a second quote
            
            Another text that is not a quote
            """
        )
        AssertSnapshot(view)
    }
    
    func test_inlinePresentationIntents() {
        let view = contentView(
            """
            **This is bold text with 2 letters for a newline**  
            _This text is italicized_

            ~~This was mistaken text with backlash for a newline~~\\
            **This text is _extremely_ important**

            ***All this text is important***
            """
        )
        AssertSnapshot(view)
    }
    
    func test_thematicBreak() {
        let view = contentView(
            """
            ---
            hi!
            """
        )
        AssertSnapshot(view)
    }
    
    func test_thematicBreak_custom() {
        var styles = MarkdownStyles()
        styles.bodyFont.color = .systemBlue
        let view = contentView(
            styles: styles,
            """
            ---
            hi!
            """
        )
        AssertSnapshot(view)
    }
    
    // MARK: -
    
    func contentView(styles: MarkdownStyles = MarkdownStyles(), _ markdown: String) -> ChatMessageContentView {
        let formatter = DefaultMarkdownFormatter()
        formatter.styles = styles
        var appearance = Appearance.default
        appearance.formatters.markdownFormatter = formatter
        let channel = ChatChannel.mock(cid: .unique)
        let message = ChatMessage.mock(text: markdown)
        let layoutOptions = ChatMessageLayoutOptions([.text, .bubble])
        let view = ChatMessageContentView().withoutAutoresizingMaskConstraints
        view.widthAnchor.constraint(equalToConstant: 480).isActive = true
        view.appearance = appearance
        view.components = .default
        view.setUpLayoutIfNeeded(options: layoutOptions, attachmentViewInjectorType: nil)
        view.content = message
        view.channel = channel
        return view
    }
}
