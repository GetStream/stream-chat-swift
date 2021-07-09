//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class iMessageComposerView: ComposerView {
    lazy var emojiButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "face.smiling.fill"), for: .normal)
        return button
    }()

    override func setUpLayout() {
        super.setUpLayout()

        // Move the send button from the trailing container to input container
        trailingContainer.removeArrangedSubview(sendButton)
        inputMessageView.inputTextContainer.addArrangedSubview(sendButton)

        // Remove spacing in leading container for bigger attachment button
        leadingContainer.spacing = 0

        // Make send button inside input container aligned to bottom
        inputMessageView.inputTextContainer.alignment = .bottom

        // Make the attachment button (camera button) bigger
        attachmentButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        attachmentButton.heightAnchor.constraint(equalToConstant: 30).isActive = true

        // Add the emoji button to the left side of attachment button
        leadingContainer.insertArrangedSubview(emojiButton, at: 0)
        // Make the emoji button same size as attachment button
        emojiButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        emojiButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
    override func setUpAppearance() {
        super.setUpAppearance()

        // Adjust the input corner radius since width is now bigger
        inputMessageView.container.layer.cornerRadius = 18
    }
}
