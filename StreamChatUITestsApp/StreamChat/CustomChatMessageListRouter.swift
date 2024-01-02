//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatUI
import StreamChat

final class CustomMessageListRouter: ChatMessageListRouter {

    var onThreadViewWillAppear: ((ThreadVC) -> Void)?

    override func showThread(messageId: MessageId, cid: ChannelId, client: ChatClient) {
        let threadVC = components.threadVC.init()
        threadVC.channelController = client.channelController(for: cid)
        threadVC.messageController = client.messageController(
            cid: cid,
            messageId: messageId
        )

        if let vc = threadVC as? ThreadVC {
            vc.onViewWillAppear = { [weak self] _ in
                self?.onThreadViewWillAppear?(vc)
            }
        }
        rootNavigationController?.show(threadVC, sender: self)
    }

    override func showThread(messageId: MessageId, at replyId: MessageId?, cid: ChannelId, client: ChatClient) {
        let threadVC = components.threadVC.init()
        threadVC.initialReplyId = replyId
        threadVC.channelController = client.channelController(for: cid)
        threadVC.messageController = client.messageController(
            cid: cid,
            messageId: messageId
        )

        if let vc = threadVC as? ThreadVC {
            vc.onViewWillAppear = { [weak self] _ in
                self?.onThreadViewWillAppear?(vc)
            }
        }
        rootNavigationController?.show(threadVC, sender: self)
    }

}
