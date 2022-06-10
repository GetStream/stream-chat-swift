//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatUI

final class DemoChatMessageContentView: ChatMessageContentView {
    override func updateContent() {
        super.updateContent()

        if content?.isShadowed == true {
            textView?.textColor = appearance.colorPalette.textLowEmphasis
            textView?.text = "This message is from a shadow banned user"
        }

        if let translations = content?.translations, let turkishTranslation = translations[.turkish] {
            textView?.text = turkishTranslation
            if let timestampLabelText = timestampLabel?.text {
                timestampLabel?.text = "\(timestampLabelText) - Translated to Turkish"
            }
        }

        guard let authorNameLabel = authorNameLabel, authorNameLabel.text?.isEmpty == true else {
            return
        }

        guard let birthLand = content?.author.birthLand else {
            return
        }

        authorNameLabel.text?.append(" \(birthLand)")
    }
}
