//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreLocation
import StreamChat
import StreamChatUI
import UIKit

class DemoComposerVC: ComposerVC {
    override func setUp() {
        super.setUp()

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(sendButtonLongPressed(_:)))
        composerView.sendButton.addGestureRecognizer(longPress)
    }

    override var attachmentsPickerActions: [UIAlertAction] {
        var actions = super.attachmentsPickerActions

        let isLocationEnabled = channelController?.channel?.config.sharedLocationsEnabled == true
        if isLocationEnabled && content.isInsideThread == false {
            let locationAction = UIAlertAction(
                title: "Location",
                style: .default,
                handler: { [weak self] _ in
                    self?.presentLocationSelection()
                }
            )
            actions.append(locationAction)
        }

        return actions
    }

    func presentLocationSelection() {
        guard let channelController = channelController else { return }
        
        let locationSelectionVC = LocationSelectionViewController(channelController: channelController)
        let navigationController = UINavigationController(rootViewController: locationSelectionVC)
        
        present(navigationController, animated: true)
    }

    // MARK: - Scheduled Messages

    var canScheduleContent: Bool {
        DemoScheduledMessagesService.shared.canScheduleMessages(in: channelController?.channel)
            && content.editingMessage == nil
            && !content.hasCommand
            && !content.isEmpty
            && !hasProcessingAttachments
    }

    var scheduledContent: DemoScheduledMessage.Content {
        let text = content.inputText
        let mentionedUserIds = content.mentionedUsers
            .filter { text.contains("@\($0.name ?? $0.id)") }
            .map(\.id)
        return DemoScheduledMessage.Content(
            text: text,
            attachments: content.attachments,
            mentionedUserIds: mentionedUserIds,
            quotedMessageId: content.quotingMessage?.id,
            parentId: content.threadMessage?.id,
            showReplyInChannel: content.threadMessage != nil && composerView.checkboxControl.isSelected,
            extraData: content.extraData
        )
    }

    @objc private func sendButtonLongPressed(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began, canScheduleContent else { return }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DemoScheduleMessagePicker.present(from: self, sourceView: composerView.sendButton) { [weak self] date in
            self?.scheduleContent(at: date)
        }
    }

    private func scheduleContent(at date: Date) {
        guard let cid = channelController?.cid else { return }

        if !canSendLinks && inputContainsLinks {
            presentAlert(title: L10n.Composer.LinksDisabled.title, message: L10n.Composer.LinksDisabled.subtitle)
            return
        }

        DemoScheduledMessagesService.shared.schedule(cid: cid, content: scheduledContent, scheduledAt: date) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(message):
                clearContent(sender: composerView.sendButton)
                let time = DemoScheduledDateFormatter.string(from: message.scheduledAt)
                DemoToastView.show("Message scheduled for \(time)", in: view)
            case let .failure(error):
                presentAlert(title: "Couldn't schedule message", message: error.localizedDescription)
            }
        }
    }
}

class DemoInputTextView: InputTextView {
    override func setUpAppearance() {
        backgroundColor = .clear
        textContainer.lineFragmentPadding = 8
        font = appearance.fonts.body
        textColor = appearance.colorPalette.textPrimary
        textAlignment = .natural
        adjustsFontForContentSizeCategory = true

        // Calling the layoutManager in debug builds loads a dynamic lib
        // Which causes a big performance penalty. So in our Demo App
        // we avoid the performance penalty, unless it is using the our internal scheme.
        if StreamRuntimeCheck.isStreamInternalConfiguration {
            layoutManager.allowsNonContiguousLayout = false
        }

        placeholderLabel.font = font
        placeholderLabel.textColor = appearance.colorPalette.textSecondary
        placeholderLabel.adjustsFontSizeToFitWidth = true
    }
}
