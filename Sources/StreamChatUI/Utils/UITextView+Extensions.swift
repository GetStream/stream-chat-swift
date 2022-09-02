//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

extension UITextView {
    func highlightMention(mention: String, color: UIColor = .systemBlue) {
        let attributeTxt = NSMutableAttributedString(attributedString: attributedText)
        let string = attributeTxt.string
        guard let range = string.range(of: mention, options: .caseInsensitive).map({ NSRange($0, in: string) }) else { return }
        
        attributeTxt.addAttribute(.link, value: "", range: range)
        linkTextAttributes = [
            .foregroundColor: color
        ]
        attributedText = attributeTxt
    }
}
