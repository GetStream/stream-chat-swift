//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A `NavigationRouter` subclass that handles navigation actions of `ChatChannelListVC`.
public typealias ChatChannelListRouter = _ChatChannelListRouter<NoExtraData>

/// A `NavigationRouter` subclass that handles navigation actions of `ChatChannelListVC`.
open class _ChatChannelListRouter<ExtraData: ExtraDataTypes>:
    NavigationRouter<_ChatChannelListVC<ExtraData>>,
    ComponentsProvider
{
    /// Shows the view controller with the profile of the current user.
    open func showCurrentUserProfile() {
        debugPrint("Not implemented", #function)
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

    /// Presents the user with the new channel creation flow.
    open func showCreateNewChannelFlow() {
        debugPrint("Not implemented", #function)
    }
}
