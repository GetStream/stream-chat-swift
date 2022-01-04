//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIFont {
    func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor!, size: pointSize)
    }

    var bold: UIFont {
        withTraits(traits: .traitBold)
    }

    var italic: UIFont {
        withTraits(traits: .traitItalic)
    }
}
