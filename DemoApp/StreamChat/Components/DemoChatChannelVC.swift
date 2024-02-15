//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatUI
import UIKit

final class DemoChatChannelVC: ChatChannelVC, UIGestureRecognizerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        let debugButton = UIBarButtonItem(
            image: UIImage(systemName: "ladybug.fill")!,
            style: .plain,
            target: self,
            action: #selector(debugTap)
        )
        navigationItem.rightBarButtonItems?.append(debugButton)

        // Custom back button to make sure swipe back gesture is not overridden.
        let customBackButton = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        navigationItem.leftBarButtonItems = [customBackButton]
        navigationController?.interactivePopGestureRecognizer?.delegate = self
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

        channelListVC.demoRouter?.didTapMoreButton(for: cid)
    }

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }
}
