//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button for confirming actions.
open class ChatConfirmButton: _Button, AppearanceProvider {
    override open func setUpAppearance() {
        super.setUpAppearance()

        let normalStateImage = appearance.images.messageComposerConfirmEditedMessage
        setImage(normalStateImage, for: .normal)
        
        let buttonColor: UIColor = appearance.colorPalette.inactiveTint
        let disabledStateImage = appearance.images.messageComposerConfirmEditedMessage.tinted(with: buttonColor)
        setImage(disabledStateImage, for: .disabled)
    }
}
