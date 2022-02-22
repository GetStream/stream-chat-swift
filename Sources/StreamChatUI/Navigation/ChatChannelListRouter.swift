//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A `NavigationRouter` subclass that handles navigation actions of `ChatChannelListVC`.
@available(iOSApplicationExtension, unavailable)
open class ChatChannelListRouter: NavigationRouter<ChatChannelListVC>, ComponentsProvider {
    /// Shows the view controller with the profile of the current user.
    open func showCurrentUserProfile() {
        log.error(
            """
            Showing current user profile is not handled. Subclass `ChatChannelListRouter` and provide your \
            implementation of the `\(#function)` method.
            """
        )
    }

    /// Shows the view controller with messages for the provided cid.
    ///
    /// - Parameter cid: `ChannelId` of the channel the should be presented.
    ///
    open func showChannel(for cid: ChannelId) {
        let vc = components.channelVC.init()
        vc.channelController = rootViewController.controller.client.channelController(
            for: cid,
            channelListQuery: rootViewController.controller.query
        )

        guard let navController = rootNavigationController else {
            log.error("Can't push chat detail, no navigation controller available")
            return
        }
        self.rootViewController.pushWithAnimation(controller: vc)
        //navController.show(vc, sender: self)
    }

    /// Called when a user tapped `More` swipe action on a channel
    ///
    /// - Parameter cid: `ChannelId` of a channel swipe acton was used on
    open func didTapMoreButton(for cid: ChannelId) {
        log.error(
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
        log.error(
            """
            Tapping `delete` swipe action for channel is not handled. Subclass `ChatChannelListRouter` and provide your \
            implementation of the `\(#function)` method.
            """
        )
    }
}
