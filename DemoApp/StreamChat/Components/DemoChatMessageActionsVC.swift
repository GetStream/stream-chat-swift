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
            if message?.isBounced == false {
                actions.append(pinMessageActionItem())
            }

            if AppConfig.shared.demoAppConfig.isHardDeleteEnabled {
                actions.append(hardDeleteActionItem())
            }
        }

        if message?.isBounced == false {
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

            let vc = MessageDebuggerViewController(message: message)
            self?.present(UINavigationController(rootViewController: vc), animated: true)
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
        var action: (StreamChatUI.ChatMessageActionItem) -> Void
    }
}

class MessageDebuggerViewController: UITableViewController {
    let message: ChatMessage

    struct MessageDebugInfo {
        var label: String
        var value: String
    }

    var messageDebugInfo: [MessageDebugInfo] = []

    init(message: ChatMessage) {
        self.message = message
        super.init(style: .plain)
        makeMessageDebugInfo()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeMessageDebugInfo() {
        messageDebugInfo = [
            .init(label: "id", value: message.id),
            .init(label: "cid", value: message.cid?.rawValue ?? ""),
            .init(label: "text", value: message.text),
            .init(label: "type", value: message.type.rawValue)
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Message Debugger"
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messageDebugInfo.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let info = messageDebugInfo[indexPath.row]
        cell.textLabel?.text = info.value
        cell.detailTextLabel?.text = info.label
        cell.accessoryView = UIImageView(image: UIImage(systemName: "doc.on.doc")!)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let value = messageDebugInfo[indexPath.row].value
        UIPasteboard.general.string = value
        presentAlert(title: "Saved to Clipboard!", message: value)
    }
}
