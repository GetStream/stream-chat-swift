//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

extension UITextView {
    ///
    /// Reference:
    /// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextLayout/Tasks/StringHeight.html
    ///
    func calculatedTextHeight() -> CGFloat {
        // Height is not calculated correctly with empty text
        let string: String = text.isEmpty ? " " : text
        let textStorage = NSTextStorage(string: string)
        let width = frame.width - textContainerInset.right - textContainerInset.left
        let customTextContainer = NSTextContainer(size: .init(width: width, height: CGFloat.greatestFiniteMagnitude))
        let layoutManager = NSLayoutManager()
        
        layoutManager.addTextContainer(customTextContainer)
        
        textStorage.addLayoutManager(layoutManager)
        if let font = font {
            textStorage.addAttribute(.font, value: font, range: .init(0..<textStorage.length))
        }
        
        customTextContainer.lineFragmentPadding = textContainer.lineFragmentPadding
        customTextContainer.maximumNumberOfLines = textContainer.maximumNumberOfLines
        customTextContainer.lineBreakMode = textContainer.lineBreakMode
        
        layoutManager.glyphRange(for: customTextContainer)
        
        return layoutManager.usedRect(for: customTextContainer).size.height
    }
}
