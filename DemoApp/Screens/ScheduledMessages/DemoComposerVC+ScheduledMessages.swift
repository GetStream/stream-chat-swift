//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

extension DemoComposerVC: ScheduledMessageListControllerDelegate {
    var scheduledContent: DemoScheduledMessageContent {
        let text = content.inputText
        let mentionedUserIds = content.mentionedUsers
            .filter { text.contains("@\($0.name ?? $0.id)") }
            .map(\.id)
        return DemoScheduledMessageContent(
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

    private var canScheduleMessages: Bool {
        AppConfig.shared.isScheduledMessagesEnabled
            && channelController?.channel?.canScheduleMessage == true
    }

    func controller(
        _ controller: ScheduledMessageListController,
        didChangeScheduledMessages changes: [ListChange<ScheduledMessage>]
    ) {
        updateScheduledMessagesBanner()
        editingScheduledMessageDidChange(in: controller.scheduledMessages)
    }

    // MARK: - Banner

    // Like the suggestions, the banners float above the composer instead of making it taller.
    func attachScheduledBanners() {
        guard let parentView = parent?.view, scheduledMessagesBannerView.superview == nil else { return }

        for banner in [scheduledMessagesBannerView, scheduledEditingBannerView] {
            banner.translatesAutoresizingMaskIntoConstraints = false
            parentView.addSubview(banner)
            NSLayoutConstraint.activate([
                banner.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 12),
                banner.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -12),
                composerView.topAnchor.constraint(equalTo: banner.bottomAnchor, constant: 8)
            ])
        }
    }

    func updateScheduledMessagesBanner() {
        var count = 0
        if AppConfig.shared.isScheduledMessagesEnabled,
           editingScheduledMessage == nil,
           let messages = channelController?.channel?.scheduledMessages {
            let parentId = content.threadMessage?.id
            count = messages.filter { $0.isPending && $0.message.parentMessageId == parentId }.count
            let place = parentId == nil ? "channel" : "thread"
            scheduledMessagesBannerView.title = "\(count) scheduled message\(count == 1 ? "" : "s") in this \(place) · View all"
        }

        scheduledMessagesBannerView.isHidden = count == 0 || suggestionsVC.isPresented
        scheduledEditingBannerView.isHidden = editingScheduledMessage == nil || suggestionsVC.isPresented
    }

    // MARK: - Scheduling

    func presentScheduleSheet() {
        guard isContentSchedulable, canScheduleMessages else { return }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DemoScheduleMessagePicker.present(from: self, sourceView: composerView.sendButton) { [weak self] date in
            self?.scheduleContent(at: date)
        }
    }

    private func scheduleContent(at date: Date) {
        guard let channelController, let cid = channelController.cid, validateLinks() else { return }

        let content = scheduledContent
        let completion: @MainActor (Result<ScheduledMessage, Error>) -> Void = { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(message):
                clearContent(sender: composerView.sendButton)
                showToast("Message scheduled for \(DemoScheduledDateFormatter.string(from: message.scheduledAt))")
            case let .failure(error):
                presentAlert(title: "Couldn't schedule message", message: error.localizedDescription)
            }
        }

        if let parentId = content.parentId {
            channelController.client.messageController(cid: cid, messageId: parentId).scheduleReply(
                text: content.text,
                attachments: content.attachments,
                mentionedUserIds: content.mentionedUserIds,
                showReplyInChannel: content.showReplyInChannel,
                quotedMessageId: content.quotedMessageId,
                extraData: content.extraData,
                scheduledAt: date,
                completion: completion
            )
        } else {
            channelController.scheduleMessage(
                text: content.text,
                attachments: content.attachments,
                mentionedUserIds: content.mentionedUserIds,
                quotedMessageId: content.quotedMessageId,
                extraData: content.extraData,
                scheduledAt: date,
                completion: completion
            )
        }
    }

    // MARK: - Editing

    func startEditing(_ message: ScheduledMessage) {
        if editingScheduledMessage == nil {
            componentsBeforeScheduledEditing = components
            var components = components
            components.isDraftMessagesEnabled = false
            self.components = components
        }

        editingScheduledMessage = message
        editingScheduledContent = DemoScheduledMessageContent(message)
        applyEditingScheduledMessageContent()
        scheduledEditingBannerView.title = "Editing scheduled message · \(DemoScheduledDateFormatter.string(from: message.scheduledAt))"
        updateScheduledMessagesBanner()
    }

    // Channel screens load their draft into the composer when they appear, so the edited content is applied after it.
    func applyScheduledMessageEditing(starting message: ScheduledMessage?) {
        if let message {
            startEditing(message)
        } else {
            applyEditingScheduledMessageContent()
        }
    }

    func endScheduledMessageEditing() {
        guard editingScheduledMessage != nil else { return }

        editingScheduledMessage = nil
        editingScheduledContent = nil
        isSubmittingScheduledMessage = false
        if let componentsBeforeScheduledEditing {
            components = componentsBeforeScheduledEditing
        }
        componentsBeforeScheduledEditing = nil
        updateScheduledMessagesBanner()
        restoreDraftOrClearContent()
    }

    func saveEditedScheduledMessageIfNeeded() {
        guard let message = editingScheduledMessage, !isSubmittingScheduledMessage, !content.isEmpty else { return }

        let editedContent = scheduledContent
        guard editedContent != editingScheduledContent else { return }

        editingScheduledContent = editedContent
        update(message, with: editedContent, scheduledAt: nil) { result in
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
        guard let message = editingScheduledMessage, let channelController else { return }

        isSubmittingScheduledMessage = true
        let id = message.id
        let sendNow = { [weak self] in
            channelController.sendScheduledMessageNow(id: id) { error in
                self?.finishScheduledMessageSubmission(error.map { .failure($0) } ?? .success(message)) { _ in
                    "Message sent"
                }
            }
        }

        let editedContent = scheduledContent
        guard editedContent != editingScheduledContent else {
            sendNow()
            return
        }
        update(message, with: editedContent, scheduledAt: nil) { [weak self] result in
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
        update(message, with: scheduledContent, scheduledAt: date) { [weak self] result in
            self?.finishScheduledMessageSubmission(result) {
                "Message rescheduled for \(DemoScheduledDateFormatter.string(from: $0.scheduledAt))"
            }
        }
    }

    private func update(
        _ message: ScheduledMessage,
        with content: DemoScheduledMessageContent,
        scheduledAt: Date?,
        completion: @escaping @MainActor (Result<ScheduledMessage, Error>) -> Void
    ) {
        guard let channelController else { return }

        if let parentId = content.parentId {
            channelController.client.messageController(cid: message.cid, messageId: parentId).updateScheduledReply(
                id: message.id,
                text: content.text,
                attachments: content.attachments,
                mentionedUserIds: content.mentionedUserIds,
                showReplyInChannel: content.showReplyInChannel,
                quotedMessageId: content.quotedMessageId,
                extraData: content.extraData,
                scheduledAt: scheduledAt,
                completion: completion
            )
        } else {
            channelController.updateScheduledMessage(
                id: message.id,
                text: content.text,
                attachments: content.attachments,
                mentionedUserIds: content.mentionedUserIds,
                quotedMessageId: content.quotedMessageId,
                extraData: content.extraData,
                scheduledAt: scheduledAt,
                completion: completion
            )
        }
    }

    private func finishScheduledMessageSubmission(
        _ result: Result<ScheduledMessage, Error>,
        successMessage: (ScheduledMessage) -> String
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

    private func editingScheduledMessageDidChange(in messages: [ScheduledMessage]) {
        guard let editingMessage = editingScheduledMessage, !isSubmittingScheduledMessage else { return }

        guard let message = messages.first(where: { $0.id == editingMessage.id }) else {
            endScheduledMessageEditing()
            showToast("This scheduled message no longer exists")
            return
        }
        if message.status == .publishing {
            endScheduledMessageEditing()
            showToast("Your scheduled message was sent")
            return
        }
        editingScheduledMessage = message
        scheduledEditingBannerView.title = "Editing scheduled message · \(DemoScheduledDateFormatter.string(from: message.scheduledAt))"
    }

    private func applyEditingScheduledMessageContent() {
        guard let message = editingScheduledMessage, let editingContent = editingScheduledContent else { return }

        let dataStore = channelController?.dataStore
        let quotedMessage = editingContent.quotedMessageId.flatMap { dataStore?.message(id: $0) }
        let mentionedUsers = editingContent.mentionedUserIds.compactMap { dataStore?.user(id: $0) }
        content = Content(
            text: editingContent.text,
            state: quotedMessage != nil ? .quote : .new,
            editingMessage: nil,
            quotingMessage: quotedMessage,
            threadMessage: content.threadMessage,
            attachments: editingContent.attachments,
            mentionedUsers: Set(mentionedUsers),
            command: nil,
            extraData: editingContent.extraData,
            cooldownTime: content.cooldownTime,
            showReplyInChannel: message.message.showReplyInChannel
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
        DemoToastView.show(text, in: parent?.view ?? view)
    }
}

private extension DemoScheduledMessageContent {
    init(_ message: ScheduledMessage) {
        self.init(
            text: message.message.text,
            attachments: message.message.allAttachments.toAnyAttachmentPayload(),
            mentionedUserIds: message.message.mentionedUsers.map(\.id),
            quotedMessageId: message.quotedMessageId,
            parentId: message.message.parentMessageId,
            showReplyInChannel: message.message.showReplyInChannel,
            extraData: message.message.extraData
        )
    }
}
