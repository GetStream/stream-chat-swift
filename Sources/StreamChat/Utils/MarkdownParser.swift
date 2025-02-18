//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 15, *)
/// A parser for markdown which generates a styled attributed string.
public enum MarkdownParser {
    /// Creates an attributed string from a Markdown-formatted string using the provided style attributes.
    ///
    /// Apple's markdown initialiser parses markdown and adds ``NSPresentationIntent`` and ``NSInlinePresentationIntent``
    /// attributes and does not do any newline handling. All the styling related attributes (font, foregroundColor etc)
    /// and newline handling, needs to be implemented separately.
    /// UIKit and SwiftUI support different ``AttributedString`` attributes (see ``AttributeScopes.SwiftUIAttributes``,
    /// ``AttributeScopes.UIKitAttributes``, and ``AttributeScopes.FoundationAttributes``). The latter is shared by both.
    /// Therefore, we need additional parsing for presentation intent attributes and add respective style related attributes.
    ///
    /// Here is an example of a nested list which shows why we need to do such handling below (note how parent
    /// lists also show up).
    /// ```
    /// List item 1 {
    ///     NSPresentationIntent = [paragraph (id 3), listItem 1 (id 2), unorderedList (id 1)]
    /// }
    /// Nested item which is very very long and keeps going until it is wrapped {
    ///    NSPresentationIntent = [paragraph (id 6), listItem 1 (id 5), unorderedList (id 4), listItem 1 (id 2), unorderedList (id 1)]
    /// }
    /// Another nested item which is very very long and keeps going until it is wrapped {
    ///     NSPresentationIntent = [paragraph (id 9), listItem 1 (id 8), unorderedList (id 7), listItem 1 (id 5), unorderedList (id 4), listItem 1 (id 2), unorderedList (id 1)]
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - markdown: The string that contains the Markdown formatting.
    ///   - attributes: The attributes to use for the whole string.
    ///   - options: Options that affect how the Markdown string is parsed and styled.
    ///   - inlinePresentationIntentAttributes: The closure for customising attributes for inline presentation intents.
    ///   - presentationIntentAttributes: The closure for customising attributes for presentation intents. Called for quote, code, list item, and headers.
    public static func style(
        markdown: String,
        options: ParsingOptions,
        attributes: AttributeContainer,
        inlinePresentationIntentAttributes: (InlinePresentationIntent) -> AttributeContainer?,
        presentationIntentAttributes: (PresentationIntent.Kind, PresentationIntent) -> AttributeContainer?
    ) throws -> AttributedString {
        var attributedString = try AttributedString(
            markdown: markdown,
            options: AttributedString.MarkdownParsingOptions(
                allowsExtendedAttributes: true,
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible,
                languageCode: nil
            )
        )
        
        attributedString.mergeAttributes(attributes)
        
        // Inline intents are handled by rendering automatically
        for (inlinePresentationIntent, range) in attributedString.runs[\.inlinePresentationIntent] {
            guard let inlinePresentationIntent else { continue }
            guard let attributes = inlinePresentationIntentAttributes(inlinePresentationIntent) else { continue }
            attributedString[range].mergeAttributes(attributes)
        }
        
        // Style block based intents
        var previousBlockStyling: BlockStyling?
        for (presentationIntent, range) in attributedString.runs[\.presentationIntent].reversed() {
            guard let presentationIntent else { continue }
            var blockStyling = BlockStyling(range: range)
            
            for blockIntentType in presentationIntent.components {
                switch blockIntentType.kind {
                case .blockQuote:
                    blockStyling.mergedAttributes = presentationIntentAttributes(blockIntentType.kind, presentationIntent)
                    blockStyling.prependedString = "| "
                    blockStyling.succeedingNewlineCount += 1
                case .codeBlock:
                    blockStyling.mergedAttributes = presentationIntentAttributes(blockIntentType.kind, presentationIntent)
                    blockStyling.precedingNewlineCount += 1
                case .header:
                    blockStyling.mergedAttributes = presentationIntentAttributes(blockIntentType.kind, presentationIntent)
                    blockStyling.precedingNewlineCount += 1
                    blockStyling.succeedingNewlineCount += 1
                case .paragraph:
                    blockStyling.precedingNewlineCount += 1
                case .listItem(ordinal: let ordinal):
                    if blockStyling.listItemOrdinal == nil {
                        blockStyling.listItemOrdinal = ordinal
                        blockStyling.mergedAttributes = presentationIntentAttributes(blockIntentType.kind, presentationIntent)
                    }
                case .orderedList:
                    blockStyling.listId = blockIntentType.identity
                    if blockStyling.isOrdered == nil {
                        blockStyling.isOrdered = true
                    } else {
                        blockStyling.prependedString.insert("\t", at: blockStyling.prependedString.startIndex)
                    }
                case .unorderedList:
                    blockStyling.listId = blockIntentType.identity
                    if blockStyling.isOrdered == nil {
                        blockStyling.isOrdered = false
                    } else {
                        blockStyling.prependedString.insert("\t", at: blockStyling.prependedString.startIndex)
                    }
                case .thematicBreak, .table, .tableHeaderRow, .tableRow, .tableCell:
                    break
                @unknown default:
                    break
                }
            }
            // Remove presentation intent attribute from the final string because it has been handled
            attributedString[range].replaceAttributes(
                AttributeContainer().presentationIntent(presentationIntent),
                with: AttributeContainer()
            )
            // Give additional space for just text
            if presentationIntent.components.count == 1, presentationIntent.components.allSatisfy({ $0.kind == .paragraph }) {
                blockStyling.succeedingNewlineCount += 1
            }
            // Preparing list items
            if let listItemOrdinal = blockStyling.listItemOrdinal {
                if blockStyling.isOrdered == true {
                    blockStyling.prependedString.append("\(listItemOrdinal).\t")
                } else {
                    blockStyling.prependedString.append("\u{2022}\t")
                }
                // Extra space when list's last item
                if let previousBlockStyling, previousBlockStyling.listId != blockStyling.listId {
                    blockStyling.succeedingNewlineCount += 1
                }
            }
            // Inserting additional space after the current block (reverse enumeration, therefore use the previous range)
            if blockStyling.succeedingNewlineCount > 0, let previousBlockStyling {
                let newlineString = String(repeating: "\n", count: blockStyling.succeedingNewlineCount)
                let insertedString = AttributedString(newlineString, attributes: attributes)
                attributedString.insertSafely(insertedString, at: previousBlockStyling.range.lowerBound)
            }
            // Additional attributes
            if let attributes = blockStyling.mergedAttributes {
                attributedString[range].mergeAttributes(attributes)
            }
            // Inserting additional characters (list items etc)
            if !blockStyling.prependedString.isEmpty {
                let attributes = attributes.merging(blockStyling.mergedAttributes ?? AttributeContainer())
                if options.layoutDirectionLeftToRight {
                    let insertedString = AttributedString(blockStyling.prependedString, attributes: attributes)
                    attributedString.insertSafely(insertedString, at: range.lowerBound)
                } else {
                    let insertedString = AttributedString(blockStyling.prependedString.reversed(), attributes: attributes)
                    attributedString.insertSafely(insertedString, at: range.upperBound)
                }
            }
            // Spacing before the block
            if blockStyling.precedingNewlineCount > 0, attributedString.startIndex != range.lowerBound {
                let newlineString = String(repeating: "\n", count: blockStyling.precedingNewlineCount)
                let insertedString = AttributedString(newlineString, attributes: attributes)
                attributedString.insertSafely(insertedString, at: range.lowerBound)
            }
            
            previousBlockStyling = blockStyling
        }
                
        return attributedString
    }
}

@available(iOS 15, *)
extension MarkdownParser {
    /// Options that affect how the Markdown string is parsed and styled.
    public struct ParsingOptions {
        public init(layoutDirectionLeftToRight: Bool = true) {
            self.layoutDirectionLeftToRight = layoutDirectionLeftToRight
        }
        
        /// Affects insertion index for additional characters like bullets and numbers for lists.
        public var layoutDirectionLeftToRight = true
    }
}

@available(iOS 15, *)
private extension AttributedString {
    mutating func insertSafely(_ s: some AttributedStringProtocol, at index: AttributedString.Index) {
        // Inserting at the end index is same as appending
        guard index >= startIndex, index <= endIndex else { return }
        insert(s, at: index)
    }
}

// Note: newlines are used instead of paragraph style because SwiftUI does render paragraph styles
@available(iOS 15.0, *)
private struct BlockStyling {
    let range: Range<AttributedString.Index>
    var precedingNewlineCount = 0
    var succeedingNewlineCount = 0
    var mergedAttributes: AttributeContainer?
    var prependedString = ""
    var listItemOrdinal: Int?
    var listId: Int?
    var isOrdered: Bool?
}
