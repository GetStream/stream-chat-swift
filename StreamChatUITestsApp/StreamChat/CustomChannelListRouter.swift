//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
import UIKit

final class CustomChannelListRouter: ChatChannelListRouter {
    var onLeave: (() -> Void)?
    var onChannelViewWillAppear: ((ChannelVC) -> Void)?
    var onChannelListViewWillAppear: ((ChannelList) -> Void)?

    override func showCurrentUserProfile() {
        onLeave?()
    }

    override func showChannel(for cid: ChannelId) {
        showChannel(for: cid, at: nil)
    }

    override func showChannel(for cid: ChannelId, at messageId: MessageId?) {
        let vc = components.channelVC.init()

        // hook on view will appear
        if let vc = vc as? ChannelVC {
            vc.onViewWillAppear = { [weak self] channelVC in
                self?.onChannelViewWillAppear?(channelVC)
            }
        }

        let client = rootViewController.controller.client
        let channelListQuery = rootViewController.controller.query
        if let messageId {
            vc.channelController = client.channelController(
                for: ChannelQuery(cid: cid, paginationParameter: .around(messageId)),
                channelListQuery: channelListQuery
            )
        } else {
            vc.channelController = client.channelController(for: cid, channelListQuery: channelListQuery)
        }

        guard let navController = rootNavigationController else {
            log.error("Can't push chat detail, no navigation controller available")
            return
        }

        navController.show(vc, sender: self)
    }

    override func didTapMoreButton(for cid: ChannelId) {
        let debugMenu = DebugMenu.shared
        debugMenu.presentAlert(
            in: rootViewController,
            title: "Select an action",
            actions: [
                .init(title: "Show channel with message id", style: .default) { [weak self] _ in
                    guard let self else { return }
                    debugMenu.presentAlert(
                        in: self.rootViewController,
                        title: "Enter message id",
                        textFieldPlaceholder: "Message ID"
                    ) { [weak self] id in
                        guard let self, let id, !id.isEmpty else { return }
                        // The channel can only open a thread reply once the reply is in the local database.
                        let messageController = self.rootViewController.controller.client.messageController(cid: cid, messageId: id)
                        messageController.synchronize { [weak self] error in
                            guard let self else { return }
                            guard error == nil, messageController.message?.cid == cid else {
                                debugMenu.presentAlert(
                                    in: self.rootViewController,
                                    title: "Message ID does not belong to this channel",
                                    actions: []
                                )
                                return
                            }
                            self.showChannel(for: cid, at: id)
                        }
                    }
                }
            ]
        )
    }

    func channelListWillAppear(_ channelListVC: ChannelList) {
        onChannelListViewWillAppear?(channelListVC)
    }
}
