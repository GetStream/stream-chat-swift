//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageComposerSendButton = _ChatMessageComposerSendButton<NoExtraData>

internal class _ChatMessageComposerSendButton<ExtraData: ExtraDataTypes>: _ChatSquareButton<ExtraData> {
    // MARK: Underlying types
    
    internal enum Mode {
        case new, edit
    }
    
    // MARK: - Properties
    
    internal var mode: Mode = .new {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    // MARK: - Overrides
    
    override internal var isEnabled: Bool {
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
    
    override internal func setUpLayout() {
        guard let size = defaultIntrinsicContentSize else { return }
        
        heightAnchor.pin(equalToConstant: size.height).isActive = true
        widthAnchor.pin(equalToConstant: size.width).isActive = true
    }
    
    override internal func updateContent() {
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
