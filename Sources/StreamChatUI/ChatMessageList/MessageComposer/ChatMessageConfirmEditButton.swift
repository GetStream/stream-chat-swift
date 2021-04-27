//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button used for confirming editing messages in ComposerView.
open class ChatMessageConfirmEditButton: _Button, AppearanceProvider {
    override open func setUpLayout() {
        let normalStateImage = appearance.images.messageComposerSendEditedMessage
        setImage(normalStateImage, for: .normal)
        
        let buttonColor: UIColor = appearance.colorPalette.inactiveTint
        let disabledStateImage = appearance.images.messageComposerSendEditedMessage.tinted(with: buttonColor)
        setImage(disabledStateImage, for: .disabled)
    }
}
