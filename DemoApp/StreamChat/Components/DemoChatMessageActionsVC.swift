//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
import UIKit

final class DemoChatMessageActionsVC: ChatMessageActionsVC {
    // For the propose of the demo app, we add an extra hard delete message to test it.
    override var messageActions: [ChatMessageActionItem] {
        var actions = super.messageActions
        if message?.isSentByCurrentUser == true {
            if AppConfig.shared.demoAppConfig.isHardDeleteEnabled {
                actions.append(hardDeleteActionItem())
            }
        }

        if message?.isBounced == false {
            actions.append(pinMessageActionItem())
            actions.append(translateActionItem())
        }

        if AppConfig.shared.demoAppConfig.isMessageDebuggerEnabled {
            actions.append(messageDebugActionItem())
        }

        return actions
    }

    func pinMessageActionItem() -> PinMessageActionItem {
        PinMessageActionItem(
            title: message?.isPinned == false ? "Pin to Conversation" : "Unpin from Conservation",
            action: { [weak self] _ in
                guard let self = self else { return }
                if self.messageController.message?.isPinned == false {
                    self.messageController.pin(.noExpiration) { error in
                        if let error = error {
                            log.error("Error when pinning message: \(error)")
                        }
                        self.delegate?.chatMessageActionsVCDidFinish(self)
                    }
                } else {
                    self.messageController.unpin { error in
                        if let error = error {
                            log.error("Error when unpinning message: \(error)")
                        }
                        self.delegate?.chatMessageActionsVCDidFinish(self)
                    }
                }
            },
            appearance: appearance
        )
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

    func messageDebugActionItem() -> ChatMessageActionItem {
        MessageDebugActionItem { [weak self] _ in
            guard let message = self?.message else { return }
            debugPrint("Debug message", message)

            let vc = DebugObjectViewController(object: message)
            self?.present(vc, animated: true)
        }
    }

    struct PinMessageActionItem: ChatMessageActionItem {
        var title: String
        var isDestructive: Bool { false }
        let icon: UIImage
        let action: (ChatMessageActionItem) -> Void

        init(
            title: String,
            action: @escaping (ChatMessageActionItem) -> Void,
            appearance: Appearance = .default
        ) {
            self.title = title
            self.action = action
            icon = UIImage(systemName: "pin") ?? .init()
        }
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
            icon = UIImage(systemName: "flag")!
        }
    }

    struct MessageDebugActionItem: ChatMessageActionItem {
        var title: String { "Message Info" }
        var icon: UIImage { UIImage(systemName: "ladybug")! }
        var action: (ChatMessageActionItem) -> Void
    }
}
