//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

/// Custom input message view
final class YTInputChatMessageView: InputChatMessageView {
    override func setUpAppearance() {
        super.setUpAppearance()
        
        // Remove the border from the container
        container.layer.cornerRadius = 0
        container.layer.borderWidth = 0
    }
}
