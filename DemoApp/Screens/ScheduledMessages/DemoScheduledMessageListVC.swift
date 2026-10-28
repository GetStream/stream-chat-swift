//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatCommonUI
import StreamChatUI
import SwiftUI
import UIKit

/// The Scheduled tab. The list is SwiftUI; the navigation bar, the conversation screens and the date picker are UIKit.
final class DemoScheduledMessageListVC: UIHostingController<DemoScheduledMessageList>, ThemeProvider {
    var onLogout: (() -> Void)?
    var onDisconnect: (() -> Void)?

    private let currentUserController: CurrentChatUserController
    private let model: DemoScheduledMessageListModel
    private var client: ChatClient { currentUserController.client }

    lazy var userAvatarView: CurrentChatUserAvatarView = components.currentUserAvatarView.init()

    init(currentUserController: CurrentChatUserController, scheduledMessageListController: ScheduledMessageListController) {
        self.currentUserController = currentUserController
        model = DemoScheduledMessageListModel(controller: scheduledMessageListController)
        super.init(rootView: DemoScheduledMessageList(model: model, actions: .init()))
        rootView.actions = .init(
            open: { [weak self] in self?.openConversation(editing: $0) },
            reschedule: { [weak self] in self?.reschedule($0) },
            channelName: { [weak self] in self?.channelName(for: $0) ?? $0.cid.id }
        )
    }

    @available(*, unavailable)
    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Scheduled"
        userAvatarView.controller = currentUserController
        userAvatarView.addTarget(self, action: #selector(didTapOnCurrentUserAvatar), for: .touchUpInside)
        userAvatarView.translatesAutoresizingMaskIntoConstraints = false
        navigationItem.backButtonTitle = ""
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: userAvatarView)

        model.onError = { [weak self] in self?.presentAlert(title: "Something went wrong", message: $0.localizedDescription) }
        model.onSuccess = { [weak self] text in
            guard let self else { return }
            DemoToastView.show(text, in: view)
        }
        model.synchronize()
    }

    @objc private func didTapOnCurrentUserAvatar(_ sender: Any) {
        presentUserOptionsAlert(onLogout: onLogout, onDisconnect: onDisconnect, client: client)
    }

    // Channels without a name, like direct messages, are named after their members when they are in the local database.
    private func channelName(for message: ScheduledMessage) -> String {
        let localChannel = client.channelController(for: message.cid).channel
        let localName = localChannel.flatMap {
            appearance.formatters.channelName.format(channel: $0, forCurrentUserId: client.currentUserId)
        }
        return localName ?? message.channel.name ?? message.cid.id
    }

    private func openConversation(editing message: ScheduledMessage) {
        let channelController = client.channelController(for: message.cid, messageOrdering: .topToBottom)
        if let parentId = message.message.parentMessageId {
            let threadVC = DemoChatThreadVC()
            threadVC.channelController = channelController
            threadVC.messageController = client.messageController(cid: message.cid, messageId: parentId)
            threadVC.scheduledMessageToEdit = message
            navigationController?.pushViewController(threadVC, animated: true)
        } else {
            let channelVC = DemoChatChannelVC()
            channelVC.channelController = channelController
            channelVC.scheduledMessageToEdit = message
            navigationController?.pushViewController(channelVC, animated: true)
        }
    }

    private func reschedule(_ message: ScheduledMessage) {
        DemoScheduleMessagePicker.present(
            from: self,
            title: "Reschedule message",
            sourceView: view,
            initialDate: message.scheduledAt
        ) { [weak self] date in
            self?.model.reschedule(message, to: date)
        }
    }
}

// MARK: - Model

@MainActor
final class DemoScheduledMessageListModel: ObservableObject, ScheduledMessageListControllerDelegate {
    @Published private(set) var scheduledMessages: [ScheduledMessage] = []
    var onError: ((Error) -> Void)?
    var onSuccess: ((String) -> Void)?

    private let controller: ScheduledMessageListController

    init(controller: ScheduledMessageListController) {
        self.controller = controller
    }

    var pending: [ScheduledMessage] { scheduledMessages.filter { $0.status != .failed } }
    var failed: [ScheduledMessage] { scheduledMessages.filter { $0.status == .failed } }

    func synchronize() {
        controller.delegate = self
        scheduledMessages = controller.scheduledMessages
        controller.synchronize()
    }

    func controller(_ controller: ScheduledMessageListController, didChangeScheduledMessages scheduledMessages: [ScheduledMessage]) {
        self.scheduledMessages = scheduledMessages
    }

    func sendNow(_ message: ScheduledMessage) {
        controller.sendScheduledMessageNow(id: message.id) { [weak self] in self?.handle($0, "Message sent") }
    }

    func reschedule(_ message: ScheduledMessage, to date: Date) {
        controller.rescheduleMessage(id: message.id, scheduledAt: date) { [weak self] result in
            let error: Error? = if case let .failure(error) = result { error } else { nil }
            self?.handle(error, "Message rescheduled for \(DemoScheduledDateFormatter.string(from: date))")
        }
    }

    func resend(_ message: ScheduledMessage) {
        controller.resendScheduledMessage(id: message.id) { [weak self] in self?.handle($0, "Scheduling the message again") }
    }

    func delete(_ message: ScheduledMessage) {
        controller.deleteScheduledMessage(id: message.id) { [weak self] in self?.handle($0, "Scheduled message deleted") }
    }

    private func handle(_ error: Error?, _ successMessage: String) {
        if let error {
            onError?(error)
        } else {
            onSuccess?(successMessage)
        }
    }
}

// MARK: - Views

@MainActor private var colors: Appearance.ColorPalette { Appearance.default.colorPalette }
@MainActor private var images: Appearance.Images { Appearance.default.images }

struct DemoScheduledMessageList: View {
    struct Actions {
        var open: (ScheduledMessage) -> Void = { _ in }
        var reschedule: (ScheduledMessage) -> Void = { _ in }
        var channelName: (ScheduledMessage) -> String = { $0.cid.id }
    }

    @ObservedObject var model: DemoScheduledMessageListModel
    var actions: Actions
    @State private var messageToSendNow: ScheduledMessage?

    var body: some View {
        List {
            Section { rows(model.pending) }
            if !model.failed.isEmpty {
                Section("Failed to send") { rows(model.failed) }
            }
        }
        .listStyle(.plain)
        .overlay { if model.scheduledMessages.isEmpty { emptyState } }
        .background(Color(colors.backgroundCoreApp))
        .alert("Send now?", isPresented: Binding(get: { messageToSendNow != nil }, set: { if !$0 { messageToSendNow = nil } })) {
            Button("Cancel", role: .cancel) {}
            Button("Send Now") { messageToSendNow.map(model.sendNow) }
        } message: {
            Text("This message will be sent right away instead of at its scheduled time.")
        }
    }

    private func rows(_ messages: [ScheduledMessage]) -> some View {
        ForEach(messages) { message in
            Button { actions.open(message) } label: {
                DemoScheduledMessageRow(message: message, channelName: actions.channelName(message))
            }
            .disabled(message.status == .sending)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color(colors.backgroundCoreApp))
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if message.status != .sending { swipeActions(for: message) }
            }
        }
    }

    // Styled like the channel list swipe actions: icon only, with the same colors.
    @ViewBuilder private func swipeActions(for message: ScheduledMessage) -> some View {
        Button(role: .destructive) { model.delete(message) } label: { actionLabel("Delete", Image(uiImage: images.messageActionDelete)) }
            .tint(Color(colors.accentError))
        Button { actions.reschedule(message) } label: { actionLabel("Reschedule", Image(uiImage: UIImage(systemName: "clock") ?? UIImage())) }
            .tint(.yellow)
        if message.status == .failed {
            if message.failure?.isRetryable ?? true {
                Button { model.resend(message) } label: { actionLabel("Retry", Image(uiImage: UIImage(systemName: "arrow.clockwise") ?? UIImage())) }
                    .tint(Color(colors.accentPrimary))
            }
        } else if message.status == .scheduled {
            Button { messageToSendNow = message } label: { actionLabel("Send Now", Image(uiImage: images.composerSend)) }
                .tint(Color(colors.accentPrimary))
        }
    }

    // Icon only, like the UIKit swipe actions. The icons are images, so the swipe actions do not fill the symbols.
    private func actionLabel(_ title: String, _ icon: Image) -> some View {
        Label { Text(title) } icon: { icon.renderingMode(.template) }
            .labelStyle(.iconOnly)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(Color(colors.textSecondary))
            Text("No scheduled messages")
                .font(Font(Appearance.default.fonts.bodyBold))
                .foregroundColor(Color(colors.textPrimary))
            Text("Long press the send button in a channel to schedule a message.")
                .font(Font(Appearance.default.fonts.footnote))
                .foregroundColor(Color(colors.textSecondary))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
}

private struct DemoScheduledMessageRow: View {
    let message: ScheduledMessage
    let channelName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(message.message.parentMessageId == nil ? "# \(channelName)" : "Thread in # \(channelName)")
                    .font(Font(Appearance.default.fonts.bodyBold))
                    .foregroundColor(Color(colors.textPrimary))
                statusIcon
            }
            Text(status.text)
                .font(Font(Appearance.default.fonts.footnote))
                .foregroundColor(Color(status.color))
            if let preview {
                Text(preview)
                    .font(Font(Appearance.default.fonts.footnote))
                    .foregroundColor(Color(colors.textSecondary))
                    .lineLimit(2)
            }
        }
    }

    /// Shows that the message is not on the server yet, or failed to reach it, like the delivery status of a message.
    @ViewBuilder private var statusIcon: some View {
        switch message.status {
        case .preparingToSchedule:
            icon(images.messageDeliveryStatusSending, color: colors.textSecondary)
        case .failed:
            icon(images.messageDeliveryStatusFailed, color: colors.accentError)
        default:
            EmptyView()
        }
    }

    private func icon(_ image: UIImage, color: UIColor) -> some View {
        Image(uiImage: image).renderingMode(.template).resizable().scaledToFit()
            .frame(width: 16, height: 16)
            .foregroundColor(Color(color))
    }

    private var status: (text: String, color: UIColor) {
        switch message.failure {
        case let .serverRejectedScheduling(rejection):
            return (rejectionText(rejection), colors.accentError)
        case let .serverFailedPublishing(failure):
            return (failure.reason?.localizedDescription ?? "Failed to send", colors.accentError)
        case let .localDeviceFailedScheduling(failure):
            return (localFailureText(failure), colors.accentError)
        case nil:
            break
        }
        switch message.status {
        case .sending:
            return ("Sending…", colors.textSecondary)
        case .failed:
            return ("Failed to send", colors.accentError)
        default:
            return ("Send \(DemoScheduledDateFormatter.string(from: message.scheduledAt))", colors.accentPrimary)
        }
    }

    private func rejectionText(_ rejection: ScheduledMessageFailure.ServerRejection) -> String {
        if rejection.reason == .scheduledMessageSending {
            return "\(rejection.demoDescription)."
        }
        return rejection.isRetryable
            ? "\(rejection.demoDescription). Swipe to retry."
            : "\(rejection.demoDescription). Tap to edit or swipe to delete."
    }

    private func localFailureText(_ failure: ScheduledMessageFailure.LocalFailure) -> String {
        if failure.reason == .attachmentUploadFailed {
            return "An attachment could not be uploaded. Swipe to retry."
        }
        return "Could not schedule the message. Swipe to retry."
    }

    private var preview: String? {
        let attachmentsCount = message.message.allAttachments.count
        if !message.message.text.isEmpty {
            return message.message.text
        }
        return attachmentsCount > 0 ? "📎 \(attachmentsCount) attachment\(attachmentsCount == 1 ? "" : "s")" : nil
    }
}
