//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button used for final sending in ComposerView.
public typealias ChatMessageSendButton = _ChatMessageSendButton<NoExtraData>

/// Button used for final sending in ComposerView.
open class _ChatMessageSendButton<ExtraData: ExtraDataTypes>: _Button, UIConfigProvider {
    /// Override this variable to enable custom behaviour upon button enabled.
    override open var isEnabled: Bool {
        didSet {
            Animate {
                self.transform = self.isEnabled ? CGAffineTransform(rotationAngle: -CGFloat.pi / 2.0) : .identity
            }
        }
    }
    
    override open func setUpLayout() {
        let normalStateImage = uiConfig.images.messageComposerSendMessage
        setImage(normalStateImage, for: .normal)
        
        let buttonColor: UIColor = uiConfig.colorPalette.inactiveTint
        let disabledStateImage = uiConfig.images.messageComposerSendMessage.tinted(with: buttonColor)
        setImage(disabledStateImage, for: .disabled)
    }
}
