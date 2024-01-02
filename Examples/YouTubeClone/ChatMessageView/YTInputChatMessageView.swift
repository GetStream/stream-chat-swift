//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

/// Custom input message view
final class YTInputChatMessageView: InputChatMessageView {
    override func setUpAppearance() {
        super.setUpAppearance()

        // Remove the border from the container
        container.layer.borderWidth = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        container.layer.cornerRadius = 0
    }
}
