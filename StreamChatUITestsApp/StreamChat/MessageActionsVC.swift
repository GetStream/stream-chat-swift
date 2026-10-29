//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
import UIKit

final class MessageActionsVC: ChatMessageActionsVC {
    override var messageActions: [ChatMessageActionItem] {
        var actions = super.messageActions
        if message?.isSentByCurrentUser == true {
            actions.append(hardDeleteActionItem())
        }
        actions.append(copyMessageIdActionItem())

        return actions
    }

    func hardDeleteActionItem() -> ChatMessageActionItem {
        HardDeleteActionItem(
            action: { [weak self] _ in
                guard let self = self else { return }
                self.alertsRouter.showMessageDeletionConfirmationAlert { confirmed in
                    guard confirmed else { return }

                    self.messageController.deleteMessage(hard: true) { _ in
                        self.delegate?.chatMessageActionsVCDidFinish(self)
                    }
                }
            },
            appearance: appearance
        )
    }

    func copyMessageIdActionItem() -> ChatMessageActionItem {
        CopyMessageIdActionItem(
            action: { [weak self] _ in
                guard let self else { return }
                UIPasteboard.general.string = self.message?.id
                self.delegate?.chatMessageActionsVCDidFinish(self)
            },
            appearance: appearance
        )
    }

    struct CopyMessageIdActionItem: ChatMessageActionItem {
        var title: String { "Copy Message ID" }
        let icon: UIImage
        let action: (ChatMessageActionItem) -> Void

        init(
            action: @escaping (ChatMessageActionItem) -> Void,
            appearance: Appearance
        ) {
            self.action = action
            icon = appearance.images.messageActionCopy
        }
    }

    struct HardDeleteActionItem: ChatMessageActionItem {
        var title: String { "Hard Delete Message" }
        var isDestructive: Bool { true }
        let icon: UIImage
        let action: (ChatMessageActionItem) -> Void

        init(
            action: @escaping (ChatMessageActionItem) -> Void,
            appearance: Appearance
        ) {
            self.action = action
            icon = appearance.images.messageActionDelete
        }
    }
}
