//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import UIKit

struct TextHighlightOptions {
    var color: UIColor
    var font: UIFont?
}

extension UILabel {
    func highlightText(_ text: String, options: TextHighlightOptions) {
        let currentText = self.text ?? ""
        guard text.isEmpty == false && currentText.isEmpty == false else {
            return
        }
        let currentTextString = currentText as NSString
        let fullRange = NSRange(location: 0, length: currentTextString.length)

        let attributedString = NSMutableAttributedString(string: currentText)
        if let currentFont = font {
            attributedString.addAttribute(.font, value: currentFont, range: fullRange)
        }

        let highlightRange = currentTextString.range(of: text)
        attributedString.addAttribute(
            .foregroundColor,
            value: options.color,
            range: highlightRange
        )
        if let font = options.font {
            attributedString.addAttribute(
                .font,
                value: font,
                range: highlightRange
            )
        }
        attributedText = attributedString
    }
}
