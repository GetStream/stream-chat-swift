//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
import UIKit

final class DemoChatThreadListVC: ChatThreadListVC {
    lazy var userAvatarView: CurrentChatUserAvatarView = components
        .currentUserAvatarView.init()

    override func setUp() {
        super.setUp()

        title = "Threads"

        userAvatarView.controller = threadListController.client.currentUserController()
        userAvatarView.addTarget(self, action: #selector(didTapOnCurrentUserAvatar), for: .touchUpInside)
    }

    override func setUpAppearance() {
        super.setUpAppearance()

        navigationItem.backButtonTitle = ""
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: userAvatarView)
    }

    override func setUpLayout() {
        super.setUpLayout()

        userAvatarView.translatesAutoresizingMaskIntoConstraints = false
    }

    @objc public func didTapOnCurrentUserAvatar(_ sender: Any) {
        // TODO: Reuse
//        presentAlert(title: nil, actions: [
//            .init(title: "Show Profile", style: .default, handler: { [weak self] _ in
//                guard let self = self else { return }
//                let client = self.rootViewController.controller.client
//                let viewController = UserProfileViewController(currentUserController: client.currentUserController())
//                self.rootNavigationController?.pushViewController(viewController, animated: true)
//            }),
//            .init(title: "Logout", style: .destructive, handler: { [weak self] _ in
//                self?.onLogout?()
//            }),
//            .init(title: "Disconnect", style: .destructive, handler: { [weak self] _ in
//                self?.onDisconnect?()
//            })
//        ])
    }
}
