//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI

final class SlackReactionsMessagePopupVC: ChatMessagePopupVC {
    override func setUpLayout() {
        let messageView = messageContentView as? SlackChatMessageContentView
        messageView?.isInPopupView = true

        super.setUpLayout()
    }
}
