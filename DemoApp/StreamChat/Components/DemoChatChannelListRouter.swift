//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class DemoChatChannelListRouter: ChatChannelListRouter {
    enum ChannelPresentingStyle {
        case push
        case modally
        case embeddedInTabBar
    }

    var channelPresentingStyle: ChannelPresentingStyle = .push
    var onLogout: (() -> Void)?
    var onDisconnect: (() -> Void)?

    lazy var streamModalTransitioningDelegate = StreamModalTransitioningDelegate()

    func showCreateNewChannelFlow() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        if let chatViewController = storyboard.instantiateViewController(withIdentifier: "CreateChatViewController") as? CreateChatViewController {
            chatViewController.searchController = rootViewController.controller.client.userSearchController()
            rootNavigationController?.pushViewController(chatViewController, animated: true)
        }
    }

    override func showCurrentUserProfile() {
        rootViewController.presentUserOptionsAlert(
            onLogout: onLogout,
            onDisconnect: onDisconnect,
            client: rootViewController.controller.client
        )
    }

    override func showChannel(for cid: ChannelId) {
        switch channelPresentingStyle {
        case .push:
            super.showChannel(for: cid)

        case .modally:
            let vc = components.channelVC.init()
            vc.channelController = rootViewController.controller.client.channelController(for: cid)
            let navVc = UINavigationController(rootViewController: vc)
            navVc.transitioningDelegate = streamModalTransitioningDelegate
            navVc.modalPresentationStyle = .custom
            rootNavigationController?.present(navVc, animated: true, completion: nil)

        case .embeddedInTabBar:
            let vc = components.channelVC.init()
            vc.channelController = rootViewController.controller.client.channelController(for: cid)
            vc.tabBarItem = .init(title: "Chat", image: nil, tag: 0)

            let dummyViewController = UIViewController()
            dummyViewController.tabBarItem = .init(title: "Dummy", image: nil, tag: 1)

            let tabBarController = UITabBarController()
            tabBarController.view.backgroundColor = .systemBackground
            tabBarController.viewControllers = [vc, dummyViewController]
            // Make the tab bar not translucent to make sure the
            // keyboard handling works in all conditions.
            tabBarController.tabBar.isTranslucent = false

            rootNavigationController?.show(tabBarController, sender: self)
        }
    }

    override func didTapMoreButton(for cid: ChannelId) {
        presentChannelActions(for: cid)
    }

    override func didTapDeleteButton(for cid: ChannelId) {
        rootViewController.controller.client.channelController(for: cid).deleteChannel { error in
            if let error = error {
                self.rootViewController.presentAlert(title: "Channel \(cid) couldn't be deleted", message: "\(error)")
            }
        }
    }
}
