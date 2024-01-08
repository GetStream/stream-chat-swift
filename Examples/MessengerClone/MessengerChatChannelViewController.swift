//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class MessengerChatChannelViewController: ChatChannelVC {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setUpLayout() {
        super.setUpLayout()

        let callBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "phone.fill"),
            style: .plain,
            target: nil,
            action: nil
        )

        navigationItem.rightBarButtonItem = callBarButtonItem
    }
}
