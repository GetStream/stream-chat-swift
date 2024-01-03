//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

class EdgeCasesChannelList: ChatChannelListVC {
    var coordinator: EdgeCasesCoordinator!

    override func setUpAppearance() {
        super.setUpAppearance()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear")!,
            style: .done,
            target: self,
            action: #selector(didTapOnSettings)
        )
    }

    override func didTapOnCurrentUserAvatar(_ sender: Any) {
        let controller = UIAlertController(
            title: "What do you want to do?",
            message: "Options in red are producing issues",
            preferredStyle: .actionSheet
        )
        controller.addAction(
            UIAlertAction(title: "Log in without logging out (same user)", style: .default) { [weak coordinator] _ in
                coordinator?.logInWithSameUser()
            }
        )
        controller.addAction(
            UIAlertAction(title: "Log in without logging out (different user)", style: .destructive) { [weak coordinator] _ in
                coordinator?.logInWithAnotherUser()
            }
        )
        controller.addAction(
            UIAlertAction(title: "Log out / log in dance", style: .destructive) { [weak coordinator] _ in
                coordinator?.logInLogOutDance()
            }
        )
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(controller, animated: true)
    }

    @objc func didTapOnSettings() {
        let controller = EdgeCasesSettingsViewController(coordinator: coordinator)
        present(controller, animated: true)
    }
}
