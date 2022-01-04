//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

/// A button which appears in the composer used for sending messages
final class YTSendButton: _Button, AppearanceProvider {
    override func setUpAppearance() {
        // Customise the appearance to make it look like the YouTube SEND button
        setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        tintColor = .secondaryLabel
    }
}
