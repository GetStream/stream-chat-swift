//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button for confirming actions.
open class ConfirmButton: _Button, AppearanceProvider {
    override open func setUpAppearance() {
        super.setUpAppearance()

        let normalStateImage = appearance.images.confirmCheckmark
        setImage(normalStateImage, for: .normal)
        
        let buttonColor: UIColor = appearance.colorPalette.inactiveTint
        let disabledStateImage = appearance.images.confirmCheckmark.tinted(with: buttonColor)
        setImage(disabledStateImage, for: .disabled)
    }
}
