//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit.UIFont

public extension Appearance {
    struct Fonts {
        public var caption1 = UIFont.preferredFont(forTextStyle: .caption1)
        public var footnoteBold = UIFont.preferredFont(forTextStyle: .footnote).bold
        public var footnote = UIFont.preferredFont(forTextStyle: .footnote)
        public var subheadline = UIFont.preferredFont(forTextStyle: .subheadline)
        public var subheadlineBold = UIFont.preferredFont(forTextStyle: .subheadline).bold
        public var body = UIFont.preferredFont(forTextStyle: .body)
        public var bodyBold = UIFont.preferredFont(forTextStyle: .body).bold
        public var bodyItalic = UIFont.preferredFont(forTextStyle: .body).italic
        public var headline = UIFont.preferredFont(forTextStyle: .headline)
        public var headlineBold = UIFont.preferredFont(forTextStyle: .headline).bold
        public var title = UIFont.preferredFont(forTextStyle: .title1)
        public var title2 = UIFont.preferredFont(forTextStyle: .title2)
        public var title3 = UIFont.preferredFont(forTextStyle: .title3).bold
        /// A font used to render emojis as "Jumbomoji".
        public var emoji = UIFont.preferredFont(forTextStyle: .body).withSize(50)
    }
    
    struct FontsSwiftUI {
        public var caption1: Font
        public var footnoteBold: Font
        public var footnote: Font
        public var subheadline: Font
        public var subheadlineBold: Font
        public var body: Font
        public var bodyBold: Font
        public var bodyItalic: Font
        public var headline: Font
        public var headlineBold: Font
        public var title: Font
        public var title2: Font
        public var title3: Font
        public var emoji: Font
        
        init(fonts: Fonts) {
            self.caption1 = fonts.caption1.toFont
            self.footnoteBold = fonts.footnoteBold.toFont
            self.footnote = fonts.footnote.toFont
            self.subheadline = fonts.subheadline.toFont
            self.subheadlineBold = fonts.subheadlineBold.toFont
            self.body = fonts.body.toFont
            self.bodyBold = fonts.bodyBold.toFont
            self.bodyItalic = fonts.bodyItalic.toFont
            self.headline = fonts.headline.toFont
            self.headlineBold = fonts.headlineBold.toFont
            self.title = fonts.title.toFont
            self.title2 = fonts.title2.toFont
            self.title3 = fonts.title3.toFont
            self.emoji = fonts.emoji.toFont
        }
    }
}

extension UIFont {
    var inferredTextStyle: UIFont.TextStyle {
        fontDescriptor.object(forKey: .textStyle) as? UIFont.TextStyle ?? .body
    }

    var toFont: Font {
        if #available(iOS 14.0, *) {
            Font.custom(fontName,
                        size: pointSize,
                        relativeTo: inferredTextStyle.toSwiftUITextStyle)
        } else {
            Font(self)
        }
    }
}

@available(iOS 14.0, *)
extension UIFont.TextStyle {
    var toSwiftUITextStyle: Font.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title1:     return .title
        case .title2:     return .title2
        case .title3:     return .title3
        case .headline:   return .headline
        case .subheadline:return .subheadline
        case .callout:    return .callout
        case .caption1:   return .caption
        case .caption2:   return .caption2
        case .footnote:   return .footnote
        case .body:       return .body
        default:          return .body
        }
    }
}
