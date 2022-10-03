//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class SlackReactionsChatMessageActionsTransitionController: ChatMessageActionsTransitionController {
    override var selectedMessageContentViewFrame: CGRect? {
        guard let messageView = selectedMessageCell?
            .messageContentView as? SlackReactionsChatMessageContentView else {
            return super.selectedMessageContentViewFrame
        }

        var frame = super.selectedMessageContentViewFrame
        frame?.size.height -= messageView.slackReactionsView.frame.height
        frame?.origin.y += messageView.slackReactionsView.frame.height
        return frame
    }
}
