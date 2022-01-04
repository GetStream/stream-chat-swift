//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatUI
import UIKit

class CustomMessageContentView: ChatMessageContentView {
    override open func updateContent() {
        super.updateContent()
        
        if content?.isShadowed == true {
            textView?.textColor = appearance.colorPalette.textLowEmphasis
            textView?.text = "This message is from a shadow banned user"
        }
        
        guard let authorNameLabel = authorNameLabel, authorNameLabel.text != "" else {
            return
        }
        
        guard let birthLand = content?.author.birthLand else {
            return
        }

        authorNameLabel.text?.append(" \(birthLand)")
    }
}
