//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button used for final sending or confirming editing messages in ComposerView.
public typealias ChatMessageComposerSendButton = _ChatMessageComposerSendButton<NoExtraData>

/// Button used for final sending or confirming editing messages in ComposerView.
open class _ChatMessageComposerSendButton<ExtraData: ExtraDataTypes>: _ComposerButton<ExtraData> {
    /// Mode for the button
    /// - new: When user wants to send new message.
    /// - edit: When user edited his message and confirm changes.
    public enum Mode {
        case new
        case edit
    }

    /// Current mode of the button whether user is sending new message or confirming edit of his old one.
    open var mode: Mode = .new {
        didSet { updateContentIfNeeded() }
    }

    /// Override this variable to enable custom behaviour upon button enabled.
    override open var isEnabled: Bool {
        didSet {
            var transformToApply: CGAffineTransform
            if isEnabled, mode == .new {
                transformToApply = CGAffineTransform(rotationAngle: -CGFloat.pi / 2.0)
            } else {
                transformToApply = .identity
            }
            Animate {
                self.transform = transformToApply
            }
        }
    }
    
    override open func setUpLayout() {
        guard let size = defaultIntrinsicContentSize else { return }
        
        heightAnchor.pin(equalToConstant: size.height).isActive = true
        widthAnchor.pin(equalToConstant: size.width).isActive = true
    }
    
    override open func updateContent() {
        switch mode {
        case .new:
            let normalStateImage = uiConfig.images.messageComposerSendMessage
            setImageWithAnimation(normalStateImage, for: .normal)

            let buttonColor: UIColor = uiConfig.colorPalette.inactiveTint
            let disabledStateImage = uiConfig.images.messageComposerSendMessage.tinted(with: buttonColor)
            setImageWithAnimation(disabledStateImage, for: .disabled)
        case .edit:
            let normalStateImage = uiConfig.images.messageComposerSendEditedMessage
            setImageWithAnimation(normalStateImage, for: .normal)
            
            let buttonColor: UIColor = uiConfig.colorPalette.inactiveTint
            let disabledStateImage = uiConfig.images.messageComposerSendEditedMessage.tinted(with: buttonColor)
            setImageWithAnimation(disabledStateImage, for: .disabled)
        }
    }

    private func setImageWithAnimation(_ image: UIImage?, for state: UIControl.State) {
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.setImage(image, for: state)
        }, completion: nil)
    }
}
