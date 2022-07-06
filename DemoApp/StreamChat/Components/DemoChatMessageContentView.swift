//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
import UIKit

final class DemoChatMessageContentView: ChatMessageContentView {
    var pinInfoLabel: UILabel?
    
    override func layout(options: ChatMessageLayoutOptions) {
        super.layout(options: options)
        
        if options.contains(.pinInfo) {
            backgroundColor = UIColor(red: 0.984, green: 0.957, blue: 0.867, alpha: 1)
            pinInfoLabel = UILabel()
            pinInfoLabel?.font = appearance.fonts.footnote
            pinInfoLabel?.textColor = appearance.colorPalette.textLowEmphasis
            bubbleThreadFootnoteContainer.insertArrangedSubview(pinInfoLabel!, at: 0)
        }
    }
    
    override func updateContent() {
        super.updateContent()

        if content?.isShadowed == true {
            textView?.textColor = appearance.colorPalette.textLowEmphasis
            textView?.text = "This message is from a shadow banned user"
        }

        if let translations = content?.translations, let turkishTranslation = translations[.turkish] {
            textView?.text = turkishTranslation
            timestampLabel?.text?.append(" - Translated to Turkish")
        }
        
        if content?.isPinned == true, let pinInfoLabel = pinInfoLabel {
            pinInfoLabel.text = "📌 Pinned"
            if let pinDetails = content?.pinDetails {
                let pinnedByName = content?.isSentByCurrentUser == true
                    ? (content?.author.id == pinDetails.pinnedBy.id ? "You" : pinDetails.pinnedBy.name ?? pinDetails.pinnedBy.id)
                    : pinDetails.pinnedBy.name ?? pinDetails.pinnedBy.id
                pinInfoLabel.text?.append(" by \(pinnedByName)")
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
