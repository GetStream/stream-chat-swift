//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
import SwiftUI
import UIKit

final class DemoChatMessageActionsVC: ChatMessageActionsVC {
    var demoAppConfig: DemoAppConfig {
        AppConfig.shared.demoAppConfig
    }

    // For the propose of the demo app, we add an extra hard delete message to test it.
    override var messageActions: [ChatMessageActionItem] {
        var actions = super.messageActions
        if message?.isSentByCurrentUser == true {
            if demoAppConfig.isHardDeleteEnabled {
                actions.append(hardDeleteActionItem())
                actions.append(deleteForMeActionItem())
            }
        }

        if message?.isBounced == false {
            actions.append(pinMessageActionItem())
            actions.append(translateActionItem())

            let isDemoAppRemindersEnabled = demoAppConfig.isRemindersEnabled
            let isChannelRemindersEnabled = channel?.config.messageRemindersEnabled ?? false
            if isDemoAppRemindersEnabled && isChannelRemindersEnabled {
                actions.append(reminderActionItem())
                actions.append(saveForLaterActionItem())
            }
        }

        if demoAppConfig.isMessageDebuggerEnabled {
            actions.append(messageDebugActionItem())
        }

        if message?.isSentByCurrentUser == true && demoAppConfig.isMessageDeliveredInfoEnabled {
            actions.append(showMessageReadsActionItem())
        }

        let hasLocationAttachments = message?.sharedLocation != nil
        if hasLocationAttachments {
            actions.removeAll(where: { $0 is EditActionItem })
        }

        return actions
    }
    
    override func deleteActionItem() -> ChatMessageActionItem {
        DeleteActionItem(
            action: { [weak self] _ in
                guard let self = self else { return }
                self.alertsRouter.showMessageDeletionConfirmationAlert { confirmed in
                    guard confirmed else { return }

                    self.messageController.deleteMessage { _ in
                        let pollId = self.messageController.message?.poll?.id
                        if let pollId, self.demoAppConfig.shouldDeletePollOnMessageDeletion {
                            let channelController = self.messageController.client.channelController(
                                for: self.messageController.cid
                            )
                            channelController.deletePoll(pollId: pollId) { _ in
                                self.delegate?.chatMessageActionsVCDidFinish(self)
                            }
                        } else {
                            self.delegate?.chatMessageActionsVCDidFinish(self)
                        }
                    }
                }
            },
            appearance: appearance
        )
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

    func deleteForMeActionItem() -> ChatMessageActionItem {
        DeleteForMeActionItem(
            action: { [weak self] _ in
                guard let self = self else { return }
                self.alertsRouter.showMessageDeletionConfirmationAlert { confirmed in
                    guard confirmed else { return }

                    self.messageController.deleteMessageForMe { _ in
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

    func reminderActionItem() -> ChatMessageActionItem {
        let hasReminder = message?.reminder != nil
        return ReminderActionItem(
            hasReminder: hasReminder,
            action: { [weak self] _ in
                guard let self = self else { return }
                
                let alertController = UIAlertController(
                    title: "Select Reminder Time",
                    message: "When would you like to be reminded?",
                    preferredStyle: .alert
                )
                
                let actions = [
                    UIAlertAction(title: "1 Minute", style: .default) { _ in
                        let remindAt = Date().addingTimeInterval(61)
                        self.updateOrCreateReminder(remindAt: remindAt)
                    },
                    UIAlertAction(title: "30 Minutes", style: .default) { _ in
                        let remindAt = Date().addingTimeInterval(30 * 60)
                        self.updateOrCreateReminder(remindAt: remindAt)
                    },
                    UIAlertAction(title: "1 Hour", style: .default) { _ in
                        let remindAt = Date().addingTimeInterval(60 * 60)
                        self.updateOrCreateReminder(remindAt: remindAt)
                    },
                    UIAlertAction(title: "Cancel", style: .cancel) { _ in
                        self.delegate?.chatMessageActionsVCDidFinish(self)
                    }
                ]
                actions.forEach { alertController.addAction($0) }
                self.present(alertController, animated: true)
            }
        )
    }

    private func updateOrCreateReminder(remindAt: Date) {
        if message?.reminder != nil {
            messageController.updateReminder(remindAt: remindAt)
        } else {
            messageController.createReminder(remindAt: remindAt)
        }
        delegate?.chatMessageActionsVCDidFinish(self)
    }

    func saveForLaterActionItem() -> ChatMessageActionItem {
        let hasReminder = message?.reminder != nil
        return SaveForLaterActionItem(
            hasReminder: message?.reminder != nil,
            action: { [weak self] _ in
                guard let self = self else { return }
                if hasReminder {
                    messageController.deleteReminder()
                } else {
                    messageController.createReminder()
                }
                self.delegate?.chatMessageActionsVCDidFinish(self)
            }
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
    
    func showMessageReadsActionItem() -> ChatMessageActionItem {
        ShowMessageReadsActionItem { [weak self] _ in
            guard let self = self,
                  let message = self.message,
                  let channel = self.channel else { return }

            let channelController = messageController.client.channelController(for: channel.cid)
            let readsView = DemoMessageReadsInfoView(message: message, channelController: channelController)
            let hostingController = UIHostingController(rootView: readsView)
            hostingController.modalPresentationStyle = .pageSheet
            
            if let sheet = hostingController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
            
            self.present(hostingController, animated: true)
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

    struct DeleteForMeActionItem: ChatMessageActionItem {
        var title: String { "Delete only for me" }
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

    struct ReminderActionItem: ChatMessageActionItem {
        var title: String
        var isDestructive: Bool { false }
        let icon: UIImage
        let action: (ChatMessageActionItem) -> Void
        
        init(
            hasReminder: Bool,
            action: @escaping (ChatMessageActionItem) -> Void
        ) {
            title = hasReminder ? "Update Reminder" : "Remind Me"
            self.action = action
            if hasReminder {
                icon = UIImage(systemName: "clock.badge.checkmark") ?? .init()
            } else {
                icon = UIImage(systemName: "clock") ?? .init()
            }
        }
    }
    
    struct SaveForLaterActionItem: ChatMessageActionItem {
        var title: String
        var isDestructive: Bool { false }
        let icon: UIImage
        let action: (ChatMessageActionItem) -> Void
        
        init(
            hasReminder: Bool,
            action: @escaping (ChatMessageActionItem) -> Void
        ) {
            title = hasReminder ? "Remove from later" : "Save for later"
            self.action = action
            if hasReminder {
                icon = UIImage(systemName: "bookmark.fill") ?? .init()
            } else {
                icon = UIImage(systemName: "bookmark") ?? .init()
            }
        }
    }
    
    struct ShowMessageReadsActionItem: ChatMessageActionItem {
        var title: String { "Show Message Reads" }
        var isDestructive: Bool { false }
        let icon: UIImage
        let action: (ChatMessageActionItem) -> Void
        
        init(action: @escaping (ChatMessageActionItem) -> Void) {
            self.action = action
            icon = UIImage(systemName: "eye") ?? .init()
        }
    }
}
