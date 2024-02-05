//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

extension UITextView {
    func highlightMention(mention: String) {
        let attributeText = NSMutableAttributedString(attributedString: attributedText)
        let string = attributeText.string

        string
            .ranges(of: mention, options: [.caseInsensitive])
            .map { NSRange($0, in: string) }
            .forEach {
                attributeText.addAttribute(.link, value: "", range: $0)
            }

        attributedText = attributeText
    }
}
