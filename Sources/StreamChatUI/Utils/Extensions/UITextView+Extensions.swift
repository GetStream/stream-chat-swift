//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import UIKit

extension UITextView {
    func highlightMention(mention: String) {
        let attributeText = NSMutableAttributedString(attributedString: attributedText)
        let string = attributeText.string
        guard let range = string
            .range(of: mention, options: .caseInsensitive)
            .map({ NSRange($0, in: string) })
        else {
            return
        }

        attributeText.addAttribute(.link, value: "", range: range)
        attributedText = attributeText
    }
}
