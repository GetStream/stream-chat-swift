//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class iMessageChatMessageComposerView: ChatMessageComposerView {
    override func setUpLayout() {
        super.setUpLayout()

        commandsButton.removeFromSuperview()
        
        messageInputView.container.preservesSuperviewLayoutMargins = false
        
        container.rightStackView.isHidden = true
        
        messageInputView.textView.setContentHuggingPriority(.required, for: .vertical)
        
        sendButton.removeFromSuperview()
        container.centerStackView.addSubview(sendButton)
        NSLayoutConstraint.activate([
            sendButton.trailingAnchor.constraint(equalTo: container.centerStackView.trailingAnchor, constant: -3.5),
            sendButton.widthAnchor.constraint(equalToConstant: 27),
            sendButton.bottomAnchor.constraint(equalTo: container.centerStackView.bottomAnchor, constant: -1.5)
        ])
    }
    
    override func setUpAppearance() {
        super.setUpAppearance()
        container.centerStackView.layer.cornerRadius = 20
        messageInputView.textView.font = .systemFont(ofSize: 15)
        
        attachmentButton.setImage(
            UIImage(systemName: "camera.fill"),
            for: .normal
        )
    }
}
