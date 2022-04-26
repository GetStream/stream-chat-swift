//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// A button for showing a countdown when Slow Mode is active.
open class CountdownButton: _Button, AppearanceProvider {
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()

        isEnabled = false
        backgroundColor = appearance.colorPalette.alternativeInactiveTint
        titleLabel?.font = appearance.fonts.bodyBold
        clipsToBounds = true
    }
}
