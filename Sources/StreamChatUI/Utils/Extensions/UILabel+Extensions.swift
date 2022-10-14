//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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

    func withNumberOfLines(_ numberOfLines: Int) -> Self {
        self.numberOfLines = numberOfLines
        return self
    }
}
