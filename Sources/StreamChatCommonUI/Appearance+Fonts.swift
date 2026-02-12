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
        public init() {}

        public var caption1: Font = .caption
        public var footnoteBold: Font = .footnote.bold()
        public var footnote: Font = .footnote
        public var subheadline: Font = .subheadline
        public var subheadlineBold: Font = .subheadline.bold()
        public var body: Font = .body
        public var bodyBold: Font = .body.bold()
        public var bodySemibold: Font = .body.weight(.semibold)
        public var bodyItalic: Font = .body.italic()
        public var headline: Font = .headline
        public var headlineBold: Font = .headline.bold()
        public var title: Font = .title

        private var _title2: Font?
        private var _title3: Font?

        // Publicly mutable properties
        public var title2: Font {
            get {
                if let v = _title2 { return v }
                if #available(iOS 14.0, *) { return .title2 }
                return .title
            }
            set { _title2 = newValue }
        }

        public var title3: Font {
            get {
                if let v = _title3 { return v }
                if #available(iOS 14.0, *) { return .title3 }
                return .title
            }
            set { _title3 = newValue }
        }

        public var emoji: Font = .system(size: 50)
    }
}
