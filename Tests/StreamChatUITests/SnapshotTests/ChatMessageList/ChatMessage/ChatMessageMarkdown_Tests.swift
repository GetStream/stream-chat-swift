//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class ChatMessageMarkdown_Tests: XCTestCase {
    let variants: [SnapshotVariant] = SnapshotVariant.all
    
    func test_text_default() {
        let view = contentView(
            """
            This is **bold** text  
            This text is _italicized_  
            This was ~~mistaken~~ text  
            This has backlashes for a newline\\
            This is regular text
            """
        )
        AssertSnapshot(view, variants: variants)
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
            This has backlashes for a newline\\
            This is regular text
            """
        )
        AssertSnapshot(view, variants: variants)
    }
    
    func test_headers_default() {
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
        AssertSnapshot(view, variants: variants)
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
        AssertSnapshot(view, variants: variants)
    }
    
    func test_unorderedLists_default() {
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
        AssertSnapshot(view, variants: variants)
    }
    
    func test_unorderedLists_nested_default() {
        let view = contentView(
            """
            Unordered (nested)  
            - First list item
                - First nested
                    - Second nested
            """
        )
        AssertSnapshot(view, variants: variants)
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
        AssertSnapshot(view, variants: variants)
    }
    
    func test_orderedLists_default() {
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
        AssertSnapshot(view, variants: variants)
    }
    
    func test_orderedLists_nested_default() {
        let view = contentView(
            """
            Unordered (nested)  
            1. First list item
                1. First nested
                    1. Second nested
                    2. Second nested (2)
            """
        )
        AssertSnapshot(view, variants: variants)
    }
    
    func test_mixedLists_nested_default() {
        let view = contentView(
            """
            Mixed (nested)  
            1. First list item
                - First nested
                    1. Second nested
                    2. Second nested (2)
            """
        )
        AssertSnapshot(view, variants: variants)
    }
    
    func test_links_default() {
        let view = contentView(
            """
            This site is cool: [Stream](https://getstream.io/)
            - *Hey*
                - This [link](https://getstream.io/) is in a list
            """
        )
        AssertSnapshot(view, variants: variants)
    }
    
    func test_code_default() {
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
        AssertSnapshot(view, variants: variants)
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
        AssertSnapshot(view, variants: variants)
    }
    
    func test_quote_default() {
        let view = contentView(
            """
            Text that is not a quote
            > Text that is a quote
            """
        )
        AssertSnapshot(view, variants: variants)
    }
    
    func test_inlinePresentationIntents_default() {
        let view = contentView(
            """
            **This is bold text with 2 letters for a newline**  
            _This text is italicized_

            ~~This was mistaken text with backlash for a newline~~\
            **This text is _extremely_ important**

            ***All this text is important***
            """
        )
        AssertSnapshot(view, variants: variants)
    }
    
    func test_thematicBreak_default() {
        let view = contentView(
            """
            ---
            hi!
            """
        )
        AssertSnapshot(view, variants: variants)
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
        AssertSnapshot(view, variants: variants)
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
