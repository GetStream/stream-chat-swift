//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button used for confirming editing messages in ComposerView.
public typealias ChatMessageConfirmEditButton = _ChatMessageConfirmEditButton<NoExtraData>

/// Button used for confirming editing messages in ComposerView.
open class _ChatMessageConfirmEditButton<ExtraData: ExtraDataTypes>: _Button, UIConfigProvider {
    override open func setUpLayout() {
        let normalStateImage = uiConfig.images.messageComposerSendEditedMessage
        setImage(normalStateImage, for: .normal)
        
        let buttonColor: UIColor = uiConfig.colorPalette.inactiveTint
        let disabledStateImage = uiConfig.images.messageComposerSendEditedMessage.tinted(with: buttonColor)
        setImage(disabledStateImage, for: .disabled)
    }
}
