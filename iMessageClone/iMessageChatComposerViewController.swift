//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class iMessageChatComposerViewController: ComposerVC {
    override func typingMention(in textView: UITextView) -> (String, NSRange)? {
        // Don't show suggestions
        nil
    }

    override func typingCommand(in textView: UITextView) -> String? {
        // Don't show suggestions
        nil
    }
    
    override func updateContent() {
        super.updateContent()

        switch content.state {
        case .new:
            composerView.inputMessageView.textView.placeholderLabel.text = "iMessage"
        default:
            break
        }
    }
}
