//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class iMessageChatMessageListViewController: ChatMessageListVC {
    override func cellContentClassForMessage(at indexPath: IndexPath) -> ChatMessageContentView.Type {
        iMessageChatMessageContentView.self
    }
}
