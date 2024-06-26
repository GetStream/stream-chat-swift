//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows a number of unread messages in a Thread.
open class ChatThreadUnreadCountView: _View, ThemeProvider {
    /// The badge view that displays the unread count.
    open private(set) lazy var badgeView = components.badgeView.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "badgeView")

    /// The number of unreads.
    open var content: Int = 0 {
        didSet { updateContentIfNeeded() }
    }

    override open func setUpLayout() {
        super.setUpLayout()

        embed(badgeView)
    }

    override open func updateContent() {
        UIView.performWithoutAnimation {
            isHidden = content == 0
            badgeView.textLabel.text = String(content)
        }
    }
}
