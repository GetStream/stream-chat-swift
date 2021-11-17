//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A Button subclass that should be used for closing.
open class CloseButton: _Button, AppearanceProvider {
    override open var isHighlighted: Bool {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        setImage(appearance.images.close, for: .normal)
    }
    
    override open func updateContent() {
        super.updateContent()
        
        if isHighlighted {
            tintColor = appearance.colorPalette.highlightedColorForColor(
                .white//appearance.colorPalette.text
            )
        } else {
            tintColor = .white//appearance.colorPalette.text
        }
    }
}
