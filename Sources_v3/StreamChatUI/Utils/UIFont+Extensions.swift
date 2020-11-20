//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIFont {
    func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor!, size: pointSize)
    }

    func bold() -> UIFont {
        withTraits(traits: .traitBold)
    }
}
