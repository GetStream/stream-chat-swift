//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

class MessageComposerInputAccessoryViewController: UIInputViewController {
    var composerView = ChatChannelMessageComposerView<DefaultUIExtraData>(uiConfig: .default).withoutAutoresizingMaskConstraints

    override func viewDidLoad() {
        super.viewDidLoad()
        inputView = composerView

        guard let inputView = inputView else { return }
        composerView.messageInputView.textView.delegate = self

        composerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        composerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        composerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        composerView.topAnchor.constraint(equalTo: inputView.topAnchor).isActive = true
    }
}

// MARK: - UITextViewDelegate

extension MessageComposerInputAccessoryViewController: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        composerView.messageInputView.textView.inputAccessoryView = view
        return true
    }

    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        composerView.messageInputView.textView.inputAccessoryView = nil
        return true
    }
}
