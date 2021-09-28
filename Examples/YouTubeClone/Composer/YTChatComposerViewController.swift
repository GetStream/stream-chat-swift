//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class YTChatComposerViewController: ComposerVC {
    // We need to cast the composerView to our new `YTChatMessageComposerView`
    // so that we can have access to the new `emojiButton`.
    var ytMessageComposerView: YTChatMessageComposerView {
        composerView as! YTChatMessageComposerView
    }
    
    override func setUp() {
        super.setUp()

        ytMessageComposerView
            .emojiButton
            .addTarget(self, action: #selector(showEmojiPicker(sender:)), for: .touchUpInside)
        ytMessageComposerView
            .dollarButton
            .addTarget(self, action: #selector(showPayOptions(sender:)), for: .touchUpInside)
    }
    
    override func typingMention(in textView: UITextView) -> (String, NSRange)? {
        nil // Don't show suggestions
    }
    
    override func typingCommand(in textView: UITextView) -> String? {
        nil // Don't show commands
    }

    override func updateContent() {
        super.updateContent()

        let currentUser = ChatClient.shared.currentUserController().currentUser
        switch content.state {
        case .new:
            composerView.inputMessageView.textView.placeholderLabel
                .text = "Chat publicly as " + (currentUser?.name ?? currentUser?.id ?? "")
        default:
            break
        }
    }
    
    // MARK: - Private Helpers
    
    @objc func showEmojiPicker(sender: UIButton) {
        // For the sake of keeping things simple for this demo app,
        // we use an alert controller to select emojis.
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
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        sheetAlertController.addAction(cancelAction)
        present(sheetAlertController, animated: true)
    }
    
    @objc func showPayOptions(sender: UIButton) {
        let sheetAlertController = UIAlertController(
            title: "Options",
            message: nil,
            preferredStyle: .actionSheet
        )
        ["Super Sticker", "Super Chat"].forEach { emoji in
            let action = UIAlertAction(title: emoji, style: .default) { action in
                debugPrint("Action - \(action.title ?? "") selected!")
            }
            sheetAlertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Close", style: .cancel, handler: nil)
        sheetAlertController.addAction(cancelAction)
        present(sheetAlertController, animated: true)
    }
}
