//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension ChatMessageListVC {
    /// Set the previous message snapshot before the data controller reports new messages.
    internal func setPreviousMessagesSnapshot(_ messages: [ChatMessage]) {
        if let dataSourceDecorator {
            listView.previousMessagesSnapshot = dataSourceDecorator(messages)
        } else {
            listView.previousMessagesSnapshot = messages
        }
    }

    /// Set the new message snapshot reported by the data controller.
    internal func setNewMessagesSnapshot(_ messages: LazyCachedMapCollection<ChatMessage>) {
        if let dataSourceDecorator {
            let filteredMessages = dataSourceDecorator(Array(messages))
            listView.currentMessagesFromDataSource = .init(source: filteredMessages, map: { $0 })
            listView.newMessagesSnapshot = .init(source: filteredMessages, map: { $0 })
        } else {
            listView.currentMessagesFromDataSource = messages
            listView.newMessagesSnapshot = messages
        }
    }
}
