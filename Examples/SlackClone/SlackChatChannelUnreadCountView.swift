//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackChatChannelUnreadCountView: ChatChannelUnreadCountView {
    override func setUpAppearance() {
        super.setUpAppearance()

        unreadCountLabel.font = .systemFont(ofSize: 10, weight: .bold)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    override func setUpLayout() {
        super.setUpLayout()

        layoutMargins = .init(top: 0, left: 6, bottom: 0, right: 6)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: heightAnchor, multiplier: 1.2)
        ])
    }
}
