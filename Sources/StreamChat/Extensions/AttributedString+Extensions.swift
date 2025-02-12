//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 15, *)
extension AttributedString {
    public init(
        markdown: String,
        attributes: AttributeContainer,
        presentationIntentAttributes: (PresentationIntent.Kind) -> AttributeContainer
    ) throws {
        let options = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: true,
            interpretedSyntax: .full,
            failurePolicy: .returnPartiallyParsedIfPossible,
            languageCode: nil
        )
        var attributedString = try AttributedString(
            markdown: markdown,
            options: options
        )
        
        attributedString.mergeAttributes(attributes)
        
        // Style block based intents
        var previousBlockStyling: BlockStyling?
        
        for (block, range) in attributedString.runs[\.presentationIntent].reversed() {
            guard let block else { continue }
            var blockStyling = BlockStyling(range: range)
            
            for blockIntentType in block.components {
                switch blockIntentType.kind {
                case .blockQuote:
                    blockStyling.mergedAttributes = presentationIntentAttributes(blockIntentType.kind)
                    blockStyling.prependedString = "| "
                    blockStyling.succeedingNewlineCount += 1
                case .codeBlock:
                    blockStyling.mergedAttributes = presentationIntentAttributes(blockIntentType.kind)
                    blockStyling.precedingNewlineCount += 1
                case .header:
                    blockStyling.mergedAttributes = presentationIntentAttributes(blockIntentType.kind)
                    blockStyling.precedingNewlineCount += 1
                    blockStyling.succeedingNewlineCount += 1
                case .paragraph:
                    blockStyling.precedingNewlineCount += 1
                case .listItem(ordinal: let ordinal):
                    if blockStyling.listItemOrdinal == nil {
                        blockStyling.listItemOrdinal = ordinal
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
            // Give additional space for just text
            if block.components.count == 1, block.components.allSatisfy({ $0.kind == .paragraph }) {
                blockStyling.succeedingNewlineCount += 1
            }
            // Preparing list items
            if let listItemOrdinal = blockStyling.listItemOrdinal {
                if blockStyling.isOrdered == true {
                    blockStyling.prependedString.append("\(listItemOrdinal).\t")
                } else {
                    blockStyling.prependedString.append("•\t")
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
                attributedString.insert(insertedString, at: previousBlockStyling.range.lowerBound)
            }
            // Additional attributes
            if let attributes = blockStyling.mergedAttributes {
                attributedString[range].mergeAttributes(attributes)
            }
            // Inserting additional characters (list items etc)
            if !blockStyling.prependedString.isEmpty {
                let attributes = attributes.merging(blockStyling.mergedAttributes ?? AttributeContainer())
                let insertedString = AttributedString(blockStyling.prependedString, attributes: attributes)
                attributedString.insert(insertedString, at: range.lowerBound)
            }
            // Spacing before the block
            if blockStyling.precedingNewlineCount > 0, attributedString.startIndex != range.lowerBound {
                let newlineString = String(repeating: "\n", count: blockStyling.precedingNewlineCount)
                let attributes = attributes.merging(blockStyling.mergedAttributes ?? AttributeContainer())
                let insertedString = AttributedString(newlineString, attributes: attributes)
                attributedString.insert(insertedString, at: range.lowerBound)
            }
            
            previousBlockStyling = blockStyling
        }
                
        self = attributedString
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
