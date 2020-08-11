//
//  UITapGestureRecognizer+Extensions.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 12/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension UITapGestureRecognizer {
    func didTapUrlIn(label: UILabel) -> URL? {
        guard let attributedText = label.attributedText else {
            return nil
        }
        
        let locationOfTouchInLabel = location(in: label)
        
        guard locationOfTouchInLabel.x >= 0, locationOfTouchInLabel.y >= 0 else {
            return nil
        }
        
        let attributedTextWithFont = NSAttributedString(string: attributedText.string,
                                                        attributes: [.font: label.font ?? UIFont.smallSystemFontSize])
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage.
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        let textStorage = NSTextStorage(attributedString: attributedTextWithFont)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Configure textContainer
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize
        
        // Find the tapped character location and compare it to the specified range.
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) / 2 - textBoundingBox.origin.x,
                                          y: (labelSize.height - textBoundingBox.size.height) / 2 - textBoundingBox.origin.y)
        
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x,
                                                     y: locationOfTouchInLabel.y - textContainerOffset.y)
        
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer,
                                                            in: textContainer,
                                                            fractionOfDistanceBetweenInsertionPoints: nil)
        
        let attributes = attributedText.attributes(at: indexOfCharacter, effectiveRange: nil)
        return (attributes[.attachment] ?? attributes[.link]) as? URL
    }
}
