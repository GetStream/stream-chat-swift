//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

class DemoChatChannelListErrorView: ChatChannelListErrorView {
    override func show() {
        UIView.animate(withDuration: 0.5) {
            self.isHidden = false
        }
    }

    override func hide() {
        UIView.animate(withDuration: 0.5) {
            self.isHidden = true
        }
    }
}
