//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatUI
import UIKit

/// A button which appears at the bottom of the chat list when the user is not viewing the latest messages. Tapping on this button scrolls to the latest messages.
final class YTScrollToLatestMessageButton: ScrollToLatestMessageButton {
    override func setUpAppearance() {
        // Customise the appearance to make it look like the YouTube scroll to bottom button
        tintColor = .white
        backgroundColor = .systemBlue
        setImage(UIImage(systemName: "arrow.down"), for: .normal)
    }
}
