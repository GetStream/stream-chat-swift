//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class MessageComposerSendButton<ExtraData: ExtraDataTypes>: ChatSquareButton<ExtraData> {
    // MARK: Underlying types
    
    public enum Mode {
        case new, edit
    }
    
    // MARK: - Properties
    
    public var mode: Mode = .new {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    // MARK: - Overrides
    
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
        
        heightAnchor.constraint(equalToConstant: size.height).isActive = true
        widthAnchor.constraint(equalToConstant: size.width).isActive = true
    }
    
    override open func updateContent() {
        switch mode {
        case .new:
            let normalStateImage = UIImage(named: "sendMessageArrow", in: .streamChatUI)
            setImageWithAnimation(normalStateImage, for: .normal)
            
            let buttonColor: UIColor = uiConfig.colorPalette.messageComposerButton
            let disabledStateImage = UIImage(named: "sendMessageArrow", in: .streamChatUI)?.tinted(with: buttonColor)
            setImageWithAnimation(disabledStateImage, for: .disabled)
        case .edit:
            let normalStateImage = UIImage(named: "editMessageCheckmark", in: .streamChatUI)
            setImageWithAnimation(normalStateImage, for: .normal)
            
            let buttonColor: UIColor = uiConfig.colorPalette.messageComposerButton
            let disabledStateImage = UIImage(named: "editMessageCheckmark", in: .streamChatUI)?.tinted(with: buttonColor)
            setImageWithAnimation(disabledStateImage, for: .disabled)
        }
    }
    
    private func setImageWithAnimation(_ image: UIImage?, for state: UIControl.State) {
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.setImage(image, for: state)
        }, completion: nil)
    }
}
