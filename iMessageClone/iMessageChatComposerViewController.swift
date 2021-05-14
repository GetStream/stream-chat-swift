//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class iMessageChatComposerViewController: ComposerVC {
    override func showCommandSuggestions(for typingCommand: String) {
        // Don't show suggestions
    }

    override func showMentionSuggestions(for typingMention: String, mentionRange: NSRange) {
        // Don't show suggestions
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
