//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class TextViewMentionedUserDetector {
    open func handleMentionedUserInteraction(on textView: UITextView, in characterRange: NSRange, _ mentionedUsers: Set<ChatUser>?, onTap: ((ChatUser?) -> Void)?) {
        guard let text = textView.text,
              let range = Range(characterRange, in: text)
        else { return }
        
        let string = String(text[range].replacingOccurrences(of: "@", with: ""))
        let user = mentionedUsers?.first(where: { $0.name == string })
        onTap?(user)
    }
}
