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
        centerRightContainer.removeArrangedSubview(sendButton)
        centerContainer.removeArrangedSubview(centerRightContainer)

        centerContentContainer.axis = .horizontal
        centerContentContainer.distribution = .natural
        centerContentContainer.alignment = .fill
        centerContentContainer.subviews.forEach {
            centerContentContainer.removeArrangedSubview($0)
        }

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

        centerContentContainer.addArrangedSubview(newStack)
        centerContentContainer.addArrangedSubview(sendButtonContainer)

        NSLayoutConstraint.activate([
            sendButton.widthAnchor.constraint(equalToConstant: 30),
            sendButton.heightAnchor.constraint(equalToConstant: 35)
        ])
    }
    
    override func setUpAppearance() {
        super.setUpAppearance()

        centerContentContainer.layer.cornerRadius = 18
        messageInputView.textView.font = .systemFont(ofSize: 15)
        
        attachmentButton.setImage(
            UIImage(systemName: "camera.fill"),
            for: .normal
        )
        attachmentButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        attachmentButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
}
