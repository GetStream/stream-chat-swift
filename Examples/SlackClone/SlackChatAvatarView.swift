//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackChatAvatarView: ChatAvatarView {
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = 5
    }
}
