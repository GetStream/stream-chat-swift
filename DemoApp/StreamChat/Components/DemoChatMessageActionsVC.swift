//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatUI
import UIKit

final class DemoChatMessageActionsVC: ChatMessageActionsVC {
    // For the propose of the demo app, we add an extra hard delete message to test it.
    override var messageActions: [ChatMessageActionItem] {
        var actions = super.messageActions
        if message?.isSentByCurrentUser == true && AppConfig.shared.demoAppConfig.isHardDeleteEnabled {
            actions.append(hardDeleteActionItem())
        }
        actions.append(translateActionItem())
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

    func translateActionItem() -> ChatMessageActionItem {
        TranslateActionitem(
            action: { [weak self] _ in
                guard let self = self else { return }
                self.messageController.translate(to: .turkish) { _ in
                    self.delegate?.chatMessageActionsVCDidFinish(self)
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

    struct TranslateActionitem: ChatMessageActionItem {
        var title: String { "Translate to Turkish" }
        var isDestructive: Bool { false }
        let icon: UIImage
        let action: (ChatMessageActionItem) -> Void

        init(
            action: @escaping (ChatMessageActionItem) -> Void,
            appearance: Appearance = .default
        ) {
            self.action = action
            icon = UIImage(systemName: "flag.fill")!
        }
    }
}
