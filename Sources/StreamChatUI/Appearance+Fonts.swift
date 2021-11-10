//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

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
        public var title3 = UIFont.preferredFont(forTextStyle: .title3).bold
        public var emoji = UIFont.systemFont(ofSize: 50)
    }
}
