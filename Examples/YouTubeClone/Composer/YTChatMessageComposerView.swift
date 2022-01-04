//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

/// The customer composer view that tries to replicate the YouTube's composer view
final class YTChatMessageComposerView: ComposerView {
    lazy var dollarButton: UIButton = {
        UIButton()
    }()
    
    lazy var emojiButton: UIButton = {
        UIButton()
    }()
    
    override func setUpLayout() {
        super.setUpLayout()

        // Remove the all the components from the composer view which are not needed
        leadingContainer.removeArrangedSubview(commandsButton)
        leadingContainer.removeArrangedSubview(attachmentButton)
        leadingContainer.removeArrangedSubview(shrinkInputButton)
        
        // Add additional components in appropriate stack
        leadingContainer.addArrangedSubview(emojiButton)
        
        // Add additional components in appropriate stack
        trailingContainer.addArrangedSubview(dollarButton)
        
        // Change the alignment
        centerContainer.alignment = .center
        trailingContainer.alignment = .center
        
        // Add constraints to the buttons we added
        NSLayoutConstraint.activate([
            dollarButton.widthAnchor.constraint(equalToConstant: 30),
            dollarButton.heightAnchor.constraint(equalToConstant: 30),
            emojiButton.widthAnchor.constraint(equalToConstant: 30),
            emojiButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    override func setUpAppearance() {
        super.setUpAppearance()
        inputMessageView.textView.layer.borderWidth = 0.0
        
        // Setup the appearance of our custom buttons
        dollarButton.setImage(UIImage(systemName: "dollarsign.square.fill"), for: .normal)
        dollarButton.tintColor = .secondaryLabel
        
        emojiButton.setImage(UIImage(systemName: "face.smiling.fill"), for: .normal)
        emojiButton.tintColor = .secondaryLabel
    }
}
