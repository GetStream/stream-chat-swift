//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class iMessageComposerVC: ComposerVC {
    var iMessageComposerView: iMessageComposerView {
        composerView as! iMessageComposerView
    }

    override func setUp() {
        super.setUp()

        iMessageComposerView.emojiButton.addTarget(self, action: #selector(showEmojiPicker), for: .touchUpInside)
    }

    override func updateContent() {
        super.updateContent()

        iMessageComposerView.emojiButton.isHidden = !content.text.isEmpty
    }

    @objc func showEmojiPicker(sender: UIButton) {
        let sheetAlertController = UIAlertController(
            title: "Emoji Picker",
            message: nil,
            preferredStyle: .actionSheet
        )

        ["😃", "😇", "😅", "😂"].forEach { emoji in

            let action = UIAlertAction(title: emoji, style: .default) { _ in
                let inputTextView = self.composerView.inputMessageView.textView
                inputTextView.replaceSelectedText(emoji)
            }

            sheetAlertController.addAction(action)
        }

        present(sheetAlertController, animated: true)
    }

    override func typingMention(in textView: UITextView) -> (String, NSRange)? {
        // Don't show suggestions
        nil
    }

    override func typingCommand(in textView: UITextView) -> String? {
        // Don't show suggestions
        nil
    }
}
