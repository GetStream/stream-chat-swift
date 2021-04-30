//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class iMessageChatMessageComposerView: ChatMessageComposerView {
    override func setUpLayout() {
        super.setUpLayout()

        centerLeftContainer.removeArrangedSubview(commandsButton)
        trailingContainer.removeArrangedSubview(sendButton)
        centerContainer.removeArrangedSubview(trailingContainer)

        centerInputContainer.axis = .horizontal
        centerInputContainer.distribution = .natural
        centerInputContainer.alignment = .fill
        centerInputContainer.removeAllArrangedSubviews()

        let newStack = ContainerStackView()
        newStack.translatesAutoresizingMaskIntoConstraints = false
        newStack.axis = .vertical
        newStack.alignment = .fill
        newStack.distribution = .natural
        newStack.spacing = 0
        newStack.addArrangedSubview(messageQuoteView)
        newStack.addArrangedSubview(imageAttachmentsView)
        newStack.addArrangedSubview(documentAttachmentsView)
        newStack.addArrangedSubview(messageInputView)
        messageInputView.container.preservesSuperviewLayoutMargins = false

        let sendButtonContainer = UIView()
        sendButtonContainer.addSubview(sendButton)
        NSLayoutConstraint.activate([
            sendButtonContainer.widthAnchor.constraint(equalToConstant: 30),
            sendButton.leadingAnchor.constraint(equalTo: sendButtonContainer.leadingAnchor, constant: 0),
            sendButton.trailingAnchor.constraint(equalTo: sendButtonContainer.trailingAnchor, constant: 0),
            sendButton.bottomAnchor.constraint(equalTo: sendButtonContainer.bottomAnchor, constant: 0)
        ])

        centerInputContainer.addArrangedSubview(newStack)
        centerInputContainer.addArrangedSubview(sendButtonContainer)

        NSLayoutConstraint.activate([
            sendButton.widthAnchor.constraint(equalToConstant: 30),
            sendButton.heightAnchor.constraint(equalToConstant: 35)
        ])
    }
    
    override func setUpAppearance() {
        super.setUpAppearance()

        centerInputContainer.layer.cornerRadius = 18
        messageInputView.inputTextView.font = .systemFont(ofSize: 15)
        
        attachmentButton.setImage(
            UIImage(systemName: "camera.fill"),
            for: .normal
        )
        attachmentButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        attachmentButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
}
