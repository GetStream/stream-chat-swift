//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A `NavigationRouter` subclass that handles navigation actions of `ChatChannelListVC`.
@available(iOSApplicationExtension, unavailable)
open class ChatThreadListRouter: NavigationRouter<ChatThreadListVC>, ComponentsProvider {
    let modalTransitioningDelegate = StreamModalTransitioningDelegate()

    /// Shows the thread from the thread list.
    /// By default it opens the `ChatThreadVC` that displays the replies.
    open func showThread(_ thread: ChatThread) {
        let client = rootViewController.threadListController.client
        let threadVC = components.threadVC.init()
        threadVC.channelController = client.channelController(for: thread.channel.cid)
        threadVC.messageController = client.messageController(
            cid: thread.channel.cid,
            messageId: thread.parentMessageId
        )

        if let splitVC = rootViewController.splitViewController {
            splitVC.showDetailViewController(UINavigationController(rootViewController: threadVC), sender: self)
        } else if let navigationVC = rootViewController.navigationController {
            navigationVC.show(threadVC, sender: self)
        } else {
            let navigationVC = UINavigationController(rootViewController: threadVC)
            navigationVC.transitioningDelegate = modalTransitioningDelegate
            navigationVC.modalPresentationStyle = .custom
            rootViewController.show(navigationVC, sender: self)
        }
    }
}
