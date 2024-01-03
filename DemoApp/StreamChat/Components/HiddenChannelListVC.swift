//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatUI
import UIKit

final class HiddenChannelListVC: ChatChannelListVC {
    override func setUpAppearance() {
        super.setUpAppearance()

        title = "Hidden Channels"
        navigationItem.leftBarButtonItem = nil
    }
}
