//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        if let channelList = self.window.rootViewController as? ChannelList {
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
