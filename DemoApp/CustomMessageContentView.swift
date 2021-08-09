//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatUI
import UIKit

class CustomMessageContentView: ChatMessageContentView {
    override open func updateContent() {
        super.updateContent()
        
        guard let authorNameLabel = authorNameLabel, authorNameLabel.text != "" else {
            return
        }
        
        guard let birthLand = content?.author.birthLand else {
            return
        }

        authorNameLabel.text?.append(" \(birthLand)")
    }
}
