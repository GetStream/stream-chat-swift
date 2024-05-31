//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
import UIKit

final class DemoChatThreadListVC: ChatThreadListVC {
    var onLogout: (() -> Void)?
    var onDisconnect: (() -> Void)?

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
        presentUserOptionsAlert(
            onLogout: onLogout,
            onDisconnect: onDisconnect,
            client: threadListController.client
        )
    }
}
