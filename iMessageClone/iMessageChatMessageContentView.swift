//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class iMessageChatMessageContentView: ChatMessageContentView {
    override func setupMetadataView() {
        super.setupMetadataView()
        
        guard let messageMetadataView = messageMetadataView else { return }
        
        messageMetadataView.timestampLabel.textAlignment = .center
        NSLayoutConstraint.activate([
            messageMetadataView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
    
    override func updateContent() {
        super.updateContent()
        
        guard let message = message else { return }
        
        if message.type == .ephemeral {
            messageBubbleView!.backgroundColor = .systemBlue
        } else {
            messageBubbleView!.backgroundColor = message.isSentByCurrentUser ? .systemBlue : .systemGray5
        }

        textView!.attributedText = .init(string: textView!.attributedText.string, attributes: [
            .foregroundColor: message.isSentByCurrentUser == true ? UIColor.white : UIColor.black,
            .font: appearance.fonts.body
        ])
    }
}
