//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A button for checking or unchecking an option.
open class CheckboxButton: _Button, AppearanceProvider {
    /// Sets the button has checked.
    open func setCheckedState() {
        setImage(appearance.images.pollVoteCheckmarkActive, for: .normal)
        tintColor = appearance.colorPalette.accentPrimary
    }
    
    /// Sets the button has unchecked.
    open func setUncheckedState() {
        setImage(appearance.images.pollVoteCheckmarkInactive, for: .normal)
        tintColor = appearance.colorPalette.inactiveTint
    }
}
