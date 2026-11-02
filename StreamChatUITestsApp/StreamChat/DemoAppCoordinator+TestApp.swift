//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

// MARK: - Navigation

extension DemoAppCoordinator {
    func start(cid: ChannelId? = nil, completion: @escaping (Error?) -> Void) {
        if let cid = cid {
            navigateToChannel(with: cid)
        } else {
            let viewController = ViewController()
            let navigationController = UINavigationController(rootViewController: viewController)
            set(rootViewController: navigationController, animated: false)
        }
        completion(nil)
    }

    private func navigateToChannel(with cid: ChannelId) {
        // Reuse the running session: a second ChatClient would race the connected one for the mock server's web socket.
        if let navigationController = window.rootViewController as? UINavigationController,
           let channelList = navigationController.viewControllers.first(where: { $0 is ChannelList }) as? ChannelList {
            navigationController.popToViewController(channelList, animated: false)
            channelList.router.showChannel(for: cid)
        } else {
            let viewController = ViewController()
            let navigationController = UINavigationController(rootViewController: viewController)
            set(rootViewController: navigationController, animated: false)
            viewController.didTap()
            viewController.router?.showChannel(for: cid)
        }
    }
}
