//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public extension ChatMessageListVC {
    /// Set the previous message snapshot before the data controller reports new messages.
    func setPreviousMessagesSnapshot(_ messages: [ChatMessage]) {
        listView.previousMessagesSnapshot = messages
    }

    /// Set the new message snapshot reported by the data controller.
    func setNewMessagesSnapshot(_ messages: LazyCachedMapCollection<ChatMessage>) {
        listView.currentMessagesFromDataSource = messages
        listView.newMessagesSnapshot = messages
    }

    /// Set the new message snapshot reported by the data controller as an Array.
    func setNewMessagesSnapshotArray(_ messages: [ChatMessage]) {
        listView.currentMessagesFromDataSourceArray = messages
        listView.newMessagesSnapshotArray = messages
    }
}
