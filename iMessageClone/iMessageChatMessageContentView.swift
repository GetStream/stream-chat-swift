//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class iMessageChatMessageContentView: ChatMessageContentView {
    override var maxContentWidthMultiplier: CGFloat { 1 }

    override func layout(options: ChatMessageLayoutOptions) {
        super.layout(options: options)

        metadataContainer?.alignment = .center
    }

    override func createTimestampLabel() -> UILabel {
        let label = super.createTimestampLabel()
        label.textAlignment = .center
        return label
    }

    override func createTextView() -> UITextView {
        let textView = super.createTextView()
        textView.font = appearance.fonts.body
        return textView
    }
    
    override func updateContent() {
        super.updateContent()

        if content?.type == .ephemeral {
            bubbleView?.backgroundColor = .systemBlue
        } else {
            bubbleView?.backgroundColor = content?.isSentByCurrentUser == true ?
                .systemBlue :
                .systemGray5
        }

        textView?.textColor = content?.isSentByCurrentUser == true ? .white : .black
    }
}

final class iMessageChatMessageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver {
    override func optionsForMessage(
        at indexPath: IndexPath,
        in channel: _ChatChannel<NoExtraData>,
        with messages: AnyRandomAccessCollection<_ChatMessage<NoExtraData>>
    ) -> ChatMessageLayoutOptions {
        var options = super.optionsForMessage(at: indexPath, in: channel, with: messages)
        options.remove(.authorName)
        return options
    }
}
