//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

extension DemoComposerVC {
    private var scheduledMessagesService: DemoScheduledMessagesService { .shared }

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

    private var isContentSchedulable: Bool {
        content.editingMessage == nil
            && !content.hasCommand
            && !content.isEmpty
            && !hasProcessingAttachments
    }

    // MARK: - Banner

    func updateScheduledMessagesBanner(with messages: [DemoScheduledMessage]) {
        var count = 0
        if AppConfig.shared.demoAppConfig.isScheduledMessagesEnabled, editingScheduledMessage == nil, let cid = channelController?.cid {
            let parentId = content.threadMessage?.id
            count = messages.filter { $0.isPending && $0.cid == cid && $0.content.parentId == parentId }.count
            let place = parentId == nil ? "channel" : "thread"
            scheduledMessagesBannerView.title = "\(count) scheduled message\(count == 1 ? "" : "s") in this \(place) · View all"
        }

        // The composer container relayouts on every `isHidden` change, and this runs on every keystroke.
        if scheduledMessagesBannerView.isHidden != (count == 0) {
            scheduledMessagesBannerView.isHidden = count == 0
        }
    }

    // MARK: - Scheduling

    func presentScheduleSheet() {
        guard isContentSchedulable, scheduledMessagesService.canScheduleMessages(in: channelController?.channel) else {
            return
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DemoScheduleMessagePicker.present(from: self, sourceView: composerView.sendButton) { [weak self] date in
            self?.scheduleContent(at: date)
        }
    }

    private func scheduleContent(at date: Date) {
        guard let cid = channelController?.cid, validateLinks() else { return }

        scheduledMessagesService.schedule(cid: cid, content: scheduledContent, scheduledAt: date) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(message):
                clearContent(sender: composerView.sendButton)
                showToast("Message scheduled for \(DemoScheduledDateFormatter.string(from: message.scheduledAt))")
            case let .failure(error):
                presentAlert(title: "Couldn't schedule message", message: error.localizedDescription)
            }
        }
    }

    // MARK: - Editing

    func startEditing(_ message: DemoScheduledMessage) {
        if editingScheduledMessage == nil {
            componentsBeforeScheduledEditing = components
            var components = components
            components.isDraftMessagesEnabled = false
            self.components = components
        }

        editingScheduledMessage = message
        applyEditingScheduledMessageContent()
        scheduledEditingBannerView.title = "Editing scheduled message · \(DemoScheduledDateFormatter.string(from: message.scheduledAt))"
        scheduledEditingBannerView.isHidden = false

        editingScheduledMessageObservation = scheduledMessagesService.$scheduledMessages
            .dropFirst()
            .sink { [weak self] messages in
                self?.editingScheduledMessageDidChange(in: messages)
            }
    }

    // Channel screens load their draft into the composer when they appear, so the edited content is applied after it.
    func applyScheduledMessageEditing(starting message: DemoScheduledMessage?) {
        if let message {
            startEditing(message)
        } else {
            applyEditingScheduledMessageContent()
        }
    }

    func endScheduledMessageEditing() {
        guard editingScheduledMessage != nil else { return }

        editingScheduledMessage = nil
        editingScheduledMessageObservation = nil
        isSubmittingScheduledMessage = false
        if let componentsBeforeScheduledEditing {
            components = componentsBeforeScheduledEditing
        }
        componentsBeforeScheduledEditing = nil
        scheduledEditingBannerView.isHidden = true
        restoreDraftOrClearContent()
    }

    func saveEditedScheduledMessageIfNeeded() {
        guard var message = editingScheduledMessage, !isSubmittingScheduledMessage, !content.isEmpty else { return }

        let editedContent = scheduledContent
        guard editedContent != message.content else { return }

        message.content = editedContent
        editingScheduledMessage = message
        scheduledMessagesService.update(id: message.id, content: editedContent) { result in
            if case let .failure(error) = result {
                log.error("Failed to save the scheduled message: \(error)")
            }
        }
    }

    func confirmSendingEditedScheduledMessage() {
        guard let message = editingScheduledMessage, !content.isEmpty, !hasProcessingAttachments, validateLinks() else {
            return
        }

        let time = DemoScheduledDateFormatter.string(from: message.scheduledAt)
        let alert = UIAlertController(
            title: "Send now?",
            message: "This message is scheduled for \(time). It will be sent right away instead.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        let sendNowAction = UIAlertAction(title: "Send Now", style: .default) { [weak self] _ in
            self?.sendEditedScheduledMessageNow()
        }
        alert.addAction(sendNowAction)
        alert.preferredAction = sendNowAction
        present(alert, animated: true)
    }

    func presentRescheduleSheet() {
        guard let message = editingScheduledMessage, isContentSchedulable else { return }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DemoScheduleMessagePicker.present(
            from: self,
            title: "Reschedule message",
            sourceView: composerView.sendButton,
            initialDate: message.scheduledAt
        ) { [weak self] date in
            self?.rescheduleEditedScheduledMessage(at: date)
        }
    }

    private func sendEditedScheduledMessageNow() {
        guard let message = editingScheduledMessage else { return }

        isSubmittingScheduledMessage = true
        let id = message.id
        let sendNow = { [weak self] in
            DemoScheduledMessagesService.shared.sendNow(id: id) { result in
                self?.finishScheduledMessageSubmission(result) { _ in "Message sent" }
            }
        }

        let editedContent = scheduledContent
        guard editedContent != message.content else {
            sendNow()
            return
        }
        scheduledMessagesService.update(id: id, content: editedContent) { [weak self] result in
            switch result {
            case .success:
                sendNow()
            case .failure:
                self?.finishScheduledMessageSubmission(result) { _ in "" }
            }
        }
    }

    private func rescheduleEditedScheduledMessage(at date: Date) {
        guard let message = editingScheduledMessage, validateLinks() else { return }

        isSubmittingScheduledMessage = true
        scheduledMessagesService.update(id: message.id, content: scheduledContent, scheduledAt: date) { [weak self] result in
            self?.finishScheduledMessageSubmission(result) {
                "Message rescheduled for \(DemoScheduledDateFormatter.string(from: $0.scheduledAt))"
            }
        }
    }

    private func finishScheduledMessageSubmission(
        _ result: Result<DemoScheduledMessage, Error>,
        successMessage: (DemoScheduledMessage) -> String
    ) {
        isSubmittingScheduledMessage = false
        switch result {
        case let .success(message):
            endScheduledMessageEditing()
            showToast(successMessage(message))
        case let .failure(error):
            presentAlert(title: "Couldn't update scheduled message", message: error.localizedDescription)
        }
    }

    private func editingScheduledMessageDidChange(in messages: [DemoScheduledMessage]) {
        guard let editingMessage = editingScheduledMessage, !isSubmittingScheduledMessage else { return }

        guard let message = messages.first(where: { $0.id == editingMessage.id }) else {
            endScheduledMessageEditing()
            showToast(DemoScheduledMessageError.notFound.localizedDescription)
            return
        }
        if message.status == .sending {
            endScheduledMessageEditing()
            showToast("Your scheduled message was sent")
        }
    }

    private func applyEditingScheduledMessageContent() {
        guard let message = editingScheduledMessage else { return }

        let dataStore = channelController?.dataStore
        let quotedMessage = message.content.quotedMessageId.flatMap { dataStore?.message(id: $0) }
        let mentionedUsers = message.content.mentionedUserIds.compactMap { dataStore?.user(id: $0) }
        content = Content(
            text: message.content.text,
            state: quotedMessage != nil ? .quote : .new,
            editingMessage: nil,
            quotingMessage: quotedMessage,
            threadMessage: content.threadMessage,
            attachments: message.content.attachments,
            mentionedUsers: Set(mentionedUsers),
            command: nil,
            extraData: message.content.extraData,
            cooldownTime: content.cooldownTime,
            showReplyInChannel: message.content.showReplyInChannel
        )
    }

    private func restoreDraftOrClearContent() {
        let draft: DraftMessage?
        if let threadId = content.threadMessage?.id, let cid = channelController?.cid {
            draft = channelController?.client.messageController(cid: cid, messageId: threadId).message?.draftReply
        } else {
            draft = channelController?.channel?.draftMessage
        }

        if let draft {
            content.draftMessage(draft)
        } else {
            clearContent(sender: composerView.sendButton)
        }
    }

    private func validateLinks() -> Bool {
        guard !canSendLinks && inputContainsLinks else { return true }

        presentAlert(title: L10n.Composer.LinksDisabled.title, message: L10n.Composer.LinksDisabled.subtitle)
        return false
    }

    private func showToast(_ text: String) {
        DemoToastView.show(text, in: view)
    }
}
