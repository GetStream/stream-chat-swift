//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackReactionsMessageActionsTransitionController: ChatMessageActionsTransitionController {
    override var selectedMessageContentViewFrame: CGRect? {
        let messageContentView = selectedMessageCell?.messageContentView
        guard let slackMessageView = messageContentView as? SlackChatMessageContentView else {
            return super.selectedMessageContentViewFrame
        }

        var frame = super.selectedMessageContentViewFrame
        frame?.size.height -= slackMessageView.slackReactionsView.frame.height
        frame?.origin.y += slackMessageView.slackReactionsView.frame.height
        return frame
    }
}
