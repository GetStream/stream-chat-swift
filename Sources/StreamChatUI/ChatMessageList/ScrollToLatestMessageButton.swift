//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// A Button that is used to indicate unread messages in the Message list.
open class ScrollToLatestMessageButton: _Button, AppearanceProvider {
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.height / 2
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        
        setImage(appearance.images.scrollDownArrow, for: .normal)
        backgroundColor = appearance.colorPalette.background8
        layer.addShadow(color: appearance.colorPalette.shadow)
    }
    
        
    }
}
