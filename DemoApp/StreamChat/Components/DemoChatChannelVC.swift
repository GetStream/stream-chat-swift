//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatUI
import UIKit

final class DemoChatChannelVC: ChatChannelVC {
    override func viewDidLoad() {
        super.viewDidLoad()

        let debugButton = UIBarButtonItem(
            image: UIImage(systemName: "ladybug.fill")!,
            style: .plain,
            target: self,
            action: #selector(debugTap)
        )
        navigationItem.rightBarButtonItems?.append(debugButton)
    }

    @objc private func debugTap() {
        guard let cid = channelController.cid else { return }

        let channelListVC: DemoChatChannelListVC
        if let mainVC = splitViewController?.viewControllers.first as? UINavigationController,
           let _channelListVC = mainVC.viewControllers.first as? DemoChatChannelListVC {
            channelListVC = _channelListVC
        } else if let _channelListVC = navigationController?.viewControllers.first as? DemoChatChannelListVC {
            channelListVC = _channelListVC
        } else {
            return
        }

        channelListVC.demoRouter.didTapMoreButton(for: cid)
    }
}
