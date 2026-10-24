//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

struct DemoScheduledActionItem: ChatMessageActionItem {
    let title: String
    let icon: UIImage
    var isDestructive = false
    let action: (ChatMessageActionItem) -> Void
}

/// A message list of scheduled messages, whose long press shows the actions of a scheduled message.
final class DemoScheduledChatMessageListVC: ChatMessageListVC {
    var actionItemsProvider: ((ChatMessage) -> [ChatMessageActionItem])?

    override func didSelectMessageCell(at indexPath: IndexPath) {
        guard
            let cell = listView.cellForRow(at: indexPath) as? ChatMessageCell,
            let messageContentView = cell.messageContentView,
            let message = messageContentView.content,
            let channel = dataSource?.channel(for: self),
            let items = actionItemsProvider?(message),
            !items.isEmpty
        else { return }

        let actionsController = DemoScheduledMessageActionsVC()
        actionsController.channel = channel
        actionsController.scheduledChatMessage = message
        actionsController.items = items.map { item in
            DemoScheduledActionItem(title: item.title, icon: item.icon, isDestructive: item.isDestructive) { [weak self] _ in
                self?.dismiss(animated: true) { item.action(item) }
            }
        }

        router.showMessageActionsPopUp(
            messageContentView: messageContentView,
            messageActionsController: actionsController,
            messageReactionsController: nil
        )
    }

    override func handlePan(_ gesture: UIPanGestureRecognizer) {}
}

final class DemoScheduledMessageActionsVC: ChatMessageActionsVC {
    var scheduledChatMessage: ChatMessage?
    var items: [ChatMessageActionItem] = []

    override var message: ChatMessage? {
        scheduledChatMessage
    }

    override var messageActions: [ChatMessageActionItem] {
        items
    }
}
