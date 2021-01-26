//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIFont {
    func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor!, size: pointSize)
    }
    
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        UIFont.systemFont(ofSize: pointSize, weight: weight)
    }

    var bold: UIFont {
        withTraits(traits: .traitBold)
    }

    var italic: UIFont {
        withTraits(traits: .traitItalic)
    }
}
