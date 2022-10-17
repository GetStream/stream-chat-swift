//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

// MARK: - Navigation

extension DemoAppCoordinator {
    
    func start(cid: ChannelId? = nil) {
        let viewController = ViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        set(rootViewController: navigationController, animated: false)
    }
}
