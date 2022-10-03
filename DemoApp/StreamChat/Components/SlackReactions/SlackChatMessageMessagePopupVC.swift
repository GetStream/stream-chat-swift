//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI

final class SlackChatMessagePopupVC: ChatMessagePopupVC {
    override func setUpLayout() {
        let messageView = messageContentView as! SlackReactionsChatMessageContentView
        messageView.isInPopupView = true
        
        super.setUpLayout()
    }
}
