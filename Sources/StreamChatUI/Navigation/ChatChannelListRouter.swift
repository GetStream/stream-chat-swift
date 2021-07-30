//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A `NavigationRouter` subclass that handles navigation actions of `ChatChannelListVC`.
public typealias ChatChannelListRouter = _ChatChannelListRouter<NoExtraData>

/// A `NavigationRouter` subclass that handles navigation actions of `ChatChannelListVC`.
open class _ChatChannelListRouter:
    NavigationRouter<_ChatChannelListVC<ExtraData>>,
    ComponentsProvider
{
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
    open func showMessageList(for cid: ChannelId) {
        let vc = components.messageListVC.init()
        vc.channelController = rootViewController.controller.client.channelController(for: cid)

        guard let navController = rootNavigationController else {
            log.error("Can't push chat detail, no navigation controller available")
            return
        }
        
        navController.show(vc, sender: self)
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
