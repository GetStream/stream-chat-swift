//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension UITextView {
    ///
    /// Reference:
    /// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextLayout/Tasks/StringHeight.html
    ///
    func calculatedTextHeight() -> CGFloat {
        let textStorage = NSTextStorage(string: text)
        let width = frame.width - textContainerInset.right - textContainerInset.left
        let customTextContainer = NSTextContainer(size: .init(width: width, height: CGFloat.greatestFiniteMagnitude))
        let layoutManager = NSLayoutManager()
        
        layoutManager.addTextContainer(customTextContainer)
        
        textStorage.addLayoutManager(layoutManager)
        textStorage.addAttribute(.font, value: font!, range: .init(0..<textStorage.length))
        
        customTextContainer.lineFragmentPadding = textContainer.lineFragmentPadding
        customTextContainer.maximumNumberOfLines = textContainer.maximumNumberOfLines
        customTextContainer.lineBreakMode = textContainer.lineBreakMode
        
        layoutManager.glyphRange(for: customTextContainer)
        
        return layoutManager.usedRect(for: customTextContainer).size.height
    }
}
