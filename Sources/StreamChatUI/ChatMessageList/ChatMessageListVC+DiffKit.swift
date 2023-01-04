//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension ChatMessageListVC {
    /// Set the previous message snapshot before the data controller reports new messages.
    internal func setPreviousMessagesSnapshot(_ messages: [ChatMessage]) {
        listView.previousMessagesSnapshot = messages
    }

    /// Set the new message snapshot reported by the data controller.
    internal func setNewMessagesSnapshot(_ messages: [ChatMessage]) {
        listView.currentMessagesFromDataSource = messages
        listView.newMessagesSnapshot = messages
    }
}
