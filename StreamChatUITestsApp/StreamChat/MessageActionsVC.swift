//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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

    struct HardDeleteActionItem: ChatMessageActionItem {
        var title: String { "Hard Delete Message" }
        var isDestructive: Bool { true }
        let icon: UIImage
        let action: (ChatMessageActionItem) -> Void

        init(
            action: @escaping (ChatMessageActionItem) -> Void,
            appearance: Appearance = .default
        ) {
            self.action = action
            icon = appearance.images.messageActionDelete
        }
    }
}
