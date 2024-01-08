//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackChatMessageListViewController: ChatMessageListVC {
    override func cellContentClassForMessage(at indexPath: IndexPath) -> ChatMessageContentView.Type {
        SlackChatMessageContentView.self
    }
}
