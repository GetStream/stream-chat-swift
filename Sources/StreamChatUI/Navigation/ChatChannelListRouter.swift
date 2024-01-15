//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A `NavigationRouter` subclass that handles navigation actions of `ChatChannelListVC`.
@available(iOSApplicationExtension, unavailable)
open class ChatChannelListRouter: NavigationRouter<ChatChannelListVC>, ComponentsProvider {
    let modalTransitioningDelegate = StreamModalTransitioningDelegate()

    /// Shows the view controller with the profile of the current user.
    open func showCurrentUserProfile() {
        log.info(
            """
            Showing current user profile is not handled. Subclass `ChatChannelListRouter` and provide your \
            implementation of the `\(#function)` method.
            """
        )
    }

    /// Shows the view controller with messages for the provided cid.
    ///
    /// - Parameter cid: The `ChannelId` of the channel the should be presented.
    open func showChannel(for cid: ChannelId) {
        showChannel(for: cid, at: nil)
    }

    /// Shows the view controller with messages for the provided cid and jumps to the given message id.
    /// - Parameters:
    ///   - cid: The `ChannelId` of the channel the should be presented.
    ///   - messageId: The `MessageId` to where the channel should jump to when opening the channel.
    open func showChannel(for cid: ChannelId, at messageId: MessageId?) {
        let vc = components.channelVC.init()

        if let messageId = messageId {
            vc.channelController = rootViewController.controller.client.channelController(
                for: ChannelQuery(
                    cid: cid,
                    pageSize: .messagesPageSize,
                    paginationParameter: .around(messageId)
                ),
                channelListQuery: rootViewController.controller.query
            )
        } else {
            vc.channelController = rootViewController.controller.client.channelController(
                for: cid,
                channelListQuery: rootViewController.controller.query
            )
        }

        if let splitVC = rootViewController.splitViewController {
            splitVC.showDetailViewController(UINavigationController(rootViewController: vc), sender: self)
        } else if let navigationVC = rootViewController.navigationController {
            navigationVC.show(vc, sender: self)
        } else {
            let navigationVC = UINavigationController(rootViewController: vc)
            navigationVC.transitioningDelegate = modalTransitioningDelegate
            navigationVC.modalPresentationStyle = .custom
            rootViewController.show(navigationVC, sender: self)
        }
    }

    /// Called when a user tapped `More` swipe action on a channel
    ///
    /// - Parameter cid: `ChannelId` of a channel swipe acton was used on
    open func didTapMoreButton(for cid: ChannelId) {
        log.info(
            """
            Tapping `more` swipe action for channel is not handled. Subclass `ChatChannelListRouter` and provide your \
            implementation of the `\(#function)` method.
            """
        )
    }

    /// Called when a user tapped `Delete` swipe action on a channel
    ///
    /// - Parameter cid: `ChannelId` of a channel swipe acton was used on
    open func didTapDeleteButton(for cid: ChannelId) {
        log.info(
            """
            Tapping `delete` swipe action for channel is not handled. Subclass `ChatChannelListRouter` and provide your \
            implementation of the `\(#function)` method.
            """
        )
    }
}
