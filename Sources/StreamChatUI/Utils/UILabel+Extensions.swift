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
}
