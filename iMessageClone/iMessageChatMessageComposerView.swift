//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class iMessageChatMessageComposerView: ComposerView {
    override func setUpLayout() {
        super.setUpLayout()

        leadingContainer.removeArrangedSubview(commandsButton)
        trailingContainer.removeArrangedSubview(sendButton)
        centerContainer.removeArrangedSubview(trailingContainer)
        inputMessageView.inputTextContainer.addArrangedSubview(sendButton)
    }
    
    override func setUpAppearance() {
        super.setUpAppearance()

        inputMessageView.layer.cornerRadius = 16
        inputMessageView.textView.font = .systemFont(ofSize: 15)
        
        attachmentButton.setImage(
            UIImage(systemName: "camera.fill"),
            for: .normal
        )
        attachmentButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        attachmentButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
}
