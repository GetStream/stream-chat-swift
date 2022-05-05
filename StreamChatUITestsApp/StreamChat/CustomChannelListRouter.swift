//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatUI
import StreamChat

final class CustomChannelListRouter: ChatChannelListRouter {

    var onLeave: (() -> Void)?
    var onChannelViewWillAppear: ((ChannelVC) -> Void)?
    var onChannelListViewWillAppear: ((ChannelList) -> Void)?

    override func showCurrentUserProfile() {
        onLeave?()
    }

    override func showChannel(for cid: ChannelId) {
        let vc = components.channelVC.init()

        // hook on view will appear
        if let vc = vc as? ChannelVC {
            vc.onViewWillAppear = { [weak self] channelVC in
                self?.onChannelViewWillAppear?(channelVC)
            }
        }

        vc.channelController = rootViewController.controller.client.channelController(
            for: cid,
            channelListQuery: rootViewController.controller.query
        )

        guard let navController = rootNavigationController else {
            log.error("Can't push chat detail, no navigation controller available")
            return
        }

        navController.show(vc, sender: self)
    }

    func channelListWillAppear(_ channelListVC: ChannelList) {
        onChannelListViewWillAppear?(channelListVC)
    }
}
