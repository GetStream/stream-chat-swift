//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class iMessageChatMessageComposerView: ChatMessageComposerView {
    override func setUpLayout() {
        super.setUpLayout()

        leadingContainer.removeArrangedSubview(commandsButton)
        trailingContainer.removeArrangedSubview(sendButton)
        centerContainer.removeArrangedSubview(trailingContainer)
        messageInputView.inputTextContainer.addArrangedSubview(sendButton)
    }
    
    override func setUpAppearance() {
        super.setUpAppearance()

        messageInputView.layer.cornerRadius = 16
        messageInputView.inputTextView.font = .systemFont(ofSize: 15)
        
        attachmentButton.setImage(
            UIImage(systemName: "camera.fill"),
            for: .normal
        )
        attachmentButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        attachmentButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
}
