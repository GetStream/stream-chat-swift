//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

extension UILabel {
    var withAdjustingFontForContentSizeCategory: Self {
        adjustsFontForContentSizeCategory = true
        return self
    }

    var withBidirectionalLanguagesSupport: Self {
        textAlignment = .natural
        return self
    }

    func textDropShadow(color: UIColor) {
        layer.shadowColor = color.cgColor
        layer.shadowRadius = 2.0
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 2, height: 2)
        layer.masksToBounds = false
    }

    func setTextSpacingBy(value: Double) {
        if let textString = self.text {
          let attributedString = NSMutableAttributedString(string: textString)
            attributedString.addAttribute(NSAttributedString.Key.kern, value: value, range: NSRange(location: 0, length: attributedString.length - 1))
          attributedText = attributedString
        }
      }
}

// MARK: - CHAT UI
extension UILabel {
    public func setChatNavTitleColor() {
        self.textColor = Appearance.default.colorPalette.chatNavigationTitleColor
        self.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold)
    }
    public func setChatNavSubtitleColor() {
        self.textColor = Appearance.default.colorPalette.chatNavigationTitleColor
        self.font = UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.regular)
    }
    public func setChatTitleColor() {
        self.textColor = UIColor.white
        self.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
    }
    public func setChatSubtitleColor() {
        self.textColor = Appearance.default.colorPalette.subTitleColor
        self.font = UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.regular)
    }
    public func setChatSubtitleBigColor() {
        self.textColor = Appearance.default.colorPalette.subTitleColor
        self.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular)
    }
}
