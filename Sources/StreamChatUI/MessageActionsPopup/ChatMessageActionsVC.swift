//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public protocol ChatMessageActionsVCDelegate: AnyObject {
    func chatMessageActionsVC(
        _ vc: ChatMessageActionsVC,
        message: ChatMessage,
        didTapOnActionItem actionItem: ChatMessageActionItem
    )
    func chatMessageActionsVCDidFinish(_ vc: ChatMessageActionsVC)
}

/// View controller to show message actions.
open class ChatMessageActionsVC: _ViewController, ThemeProvider {
    public weak var delegate: ChatMessageActionsVCDelegate?

    /// `ChatMessageController` instance used to obtain the message data.
    public var messageController: ChatMessageController!

    /// A boolean value indicating if the actions are being shown inside a thread.
    public var isInsideThread: Bool = false

    /// The channel which the actions will be performed.
    public var channel: ChatChannel? {
        didSet {
            channelConfig = channel?.config
        }
    }

    /// `ChannelConfig` that contains the feature flags of the channel.
    public var channelConfig: ChannelConfig!

    /// Message that should be shown in this view controller.
    open var message: ChatMessage? {
        messageController.message
    }

    /// The `AlertsRouter` instance responsible for presenting alerts.
    open lazy var alertsRouter = components
        .alertsRouter
        // Temporary solution until the actions router works with with the `UIWindow`
        .init(rootViewController: self.parent ?? self)

    /// `ContainerView` for showing message's actions.
    open private(set) lazy var messageActionsContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "messageActionsContainerStackView")

    /// Class used for buttons in `messageActionsContainerView`.
    open var actionButtonClass: ChatMessageActionControl.Type { ChatMessageActionControl.self }

    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(messageActionsContainerStackView)
        NSLayoutConstraint.activate([
            messageActionsContainerStackView.leadingAnchor.pin(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            messageActionsContainerStackView.trailingAnchor.pin(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            messageActionsContainerStackView.topAnchor.pin(equalTo: view.safeAreaLayoutGuide.topAnchor),
            messageActionsContainerStackView.bottomAnchor.pin(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        messageActionsContainerStackView.axis = .vertical
        messageActionsContainerStackView.alignment = .fill
        messageActionsContainerStackView.spacing = 1

        // Fix safe area layout issue when message actions go below scroll view
        messageActionsContainerStackView.insetsLayoutMarginsFromSafeArea = false
        messageActionsContainerStackView.isLayoutMarginsRelativeArrangement = true
        messageActionsContainerStackView.layoutMargins = .zero
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        messageActionsContainerStackView.layer.cornerRadius = 16
        messageActionsContainerStackView.layer.masksToBounds = true
        messageActionsContainerStackView.backgroundColor = appearance.colorPalette.border
    }

    override open func updateContent() {
        messageActionsContainerStackView.removeAllArrangedSubviews()

        messageActions.forEach {
            let actionView = actionButtonClass.init()
            actionView.containerStackView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            actionView.content = $0
            messageActionsContainerStackView.addArrangedSubview(actionView)
            actionView.accessibilityIdentifier = "\(type(of: $0))"
        }
    }

    /// Array of `ChatMessageActionItem`s - override this to setup your own custom actions
    open var messageActions: [ChatMessageActionItem] {
        guard
            let currentUser = messageController.dataStore.currentUser(),
            let message = message,
            message.isDeleted == false
        else {
            return []
        }

        switch message.localState {
        case nil:
            var actions: [ChatMessageActionItem] = []

            // If a channel is not set, we fallback to using channelConfig only.
            let canQuoteMessage = channel?.canQuoteMessage ?? channelConfig.quotesEnabled
            let canSendReply = channel?.canSendReply ?? channelConfig.repliesEnabled
            let canReceiveReadEvents = channel?.canReceiveReadEvents ?? channelConfig.readEventsEnabled
            let canUpdateAnyMessage = channel?.canUpdateAnyMessage ?? false
            let canUpdateOwnMessage = channel?.canUpdateOwnMessage ?? true
            let canDeleteAnyMessage = channel?.canDeleteAnyMessage ?? false
            let canDeleteOwnMessage = channel?.canDeleteOwnMessage ?? true
            let canFlagMessage = channel?.canFlagMessage ?? false
            let isSentByCurrentUser = message.isSentByCurrentUser

            if canQuoteMessage {
                actions.append(inlineReplyActionItem())
            }

            if canSendReply && !message.isPartOfThread && !isInsideThread {
                actions.append(threadReplyActionItem())
            }

            if canReceiveReadEvents {
                // If message is root of thread, it can be marked unread independent of other logic.
                if message.isRootOfThread {
                    actions.append(markUnreadActionItem())
                    // If the message is in the channel view, only other user messages can be marked unread.
                } else if !isSentByCurrentUser && (!message.isPartOfThread || message.showReplyInChannel) {
                    actions.append(markUnreadActionItem())
                }
            }

            if !message.text.isEmpty {
                actions.append(copyActionItem())
            }

            if message.poll == nil {
                if canUpdateAnyMessage && message.giphyAttachments.isEmpty {
                    actions.append(editActionItem())
                } else if canUpdateOwnMessage && message.isSentByCurrentUser && message.giphyAttachments.isEmpty {
                    actions.append(editActionItem())
                }
            }

            if canDeleteAnyMessage {
                actions.append(deleteActionItem())
            } else if canDeleteOwnMessage && isSentByCurrentUser {
                actions.append(deleteActionItem())
            }

            if !isSentByCurrentUser && canFlagMessage {
                actions.append(flagActionItem())
            }

            if channelConfig.mutesEnabled && !isSentByCurrentUser {
                let isMuted = currentUser.mutedUsers.map(\.id).contains(message.author.id)
                actions.append(isMuted ? unmuteActionItem() : muteActionItem())
            }
            
            if components.isBlockingUsersEnabled && !isSentByCurrentUser {
                let isBlocked = currentUser.blockedUserIds.contains(message.author.id)
                actions.append(isBlocked ? unblockActionItem() : blockActionItem())
            }

            return actions
        case .sendingFailed:
            return [
                resendActionItem(),
                editActionItem(),
                deleteActionItem()
            ]
        case .pendingSend,
             .pendingSync,
             .syncingFailed,
             .deletingFailed,
             .sending,
             .syncing,
             .deleting:
            return [
                editActionItem(),
                deleteActionItem()
            ]
        }
    }

    /// Returns `ChatMessageActionItem` for edit action
    open func editActionItem() -> ChatMessageActionItem {
        EditActionItem(
            action: { [weak self] in self?.handleAction($0) },
            appearance: appearance
        )
    }

    /// Returns `ChatMessageActionItem` for delete action
    open func deleteActionItem() -> ChatMessageActionItem {
        DeleteActionItem(
            action: { [weak self] _ in
                guard let self = self else { return }
                self.alertsRouter.showMessageDeletionConfirmationAlert { confirmed in
                    guard confirmed else { return }

                    self.messageController.deleteMessage { _ in
                        self.delegate?.chatMessageActionsVCDidFinish(self)
                    }
                }
            },
            appearance: appearance
        )
    }

    /// Returns `ChatMessageActionItem` for resend action.
    open func resendActionItem() -> ChatMessageActionItem {
        ResendActionItem(
            action: { [weak self] _ in
                guard let self = self else { return }
                self.messageController.resendMessage { _ in
                    self.delegate?.chatMessageActionsVCDidFinish(self)
                }
            },
            appearance: appearance
        )
    }

    /// Returns `ChatMessageActionItem` for mute action.
    open func muteActionItem() -> ChatMessageActionItem {
        MuteUserActionItem(
            action: { [weak self] _ in
                guard
                    let self = self,
                    let author = self.message?.author
                else { return }

                self.messageController.client
                    .userController(userId: author.id)
                    .mute { _ in self.delegate?.chatMessageActionsVCDidFinish(self) }
            },
            appearance: appearance
        )
    }

    /// Returns `ChatMessageActionItem` for unmute action.
    open func unmuteActionItem() -> ChatMessageActionItem {
        UnmuteUserActionItem(
            action: { [weak self] _ in
                guard
                    let self = self,
                    let author = self.message?.author
                else { return }

                self.messageController.client
                    .userController(userId: author.id)
                    .unmute { _ in self.delegate?.chatMessageActionsVCDidFinish(self) }
            },
            appearance: appearance
        )
    }
    
    /// Returns `ChatMessageActionItem` for block action.
    open func blockActionItem() -> ChatMessageActionItem {
        BlockUserActionItem(
            action: { [weak self] _ in
                guard
                    let self = self,
                    let author = self.message?.author
                else { return }

                self.messageController.client
                    .userController(userId: author.id)
                    .block { _ in self.delegate?.chatMessageActionsVCDidFinish(self) }
            },
            appearance: appearance
        )
    }

    /// Returns `ChatMessageActionItem` for unblock action.
    open func unblockActionItem() -> ChatMessageActionItem {
        UnblockUserActionItem(
            action: { [weak self] _ in
                guard
                    let self = self,
                    let author = self.message?.author
                else { return }

                self.messageController.client
                    .userController(userId: author.id)
                    .unblock { _ in self.delegate?.chatMessageActionsVCDidFinish(self) }
            },
            appearance: appearance
        )
    }

    /// Returns `ChatMessageActionItem` for inline reply action.
    open func inlineReplyActionItem() -> ChatMessageActionItem {
        InlineReplyActionItem(
            action: { [weak self] in self?.handleAction($0) },
            appearance: appearance
        )
    }

    /// Returns `ChatMessageActionItem` for thread reply action.
    open func threadReplyActionItem() -> ChatMessageActionItem {
        ThreadReplyActionItem(
            action: { [weak self] in self?.handleAction($0) },
            appearance: appearance
        )
    }

    /// Returns `MarkUnreadActionItem` for copy action.
    open func markUnreadActionItem() -> ChatMessageActionItem {
        MarkUnreadActionItem(
            action: { [weak self] in self?.handleAction($0) },
            appearance: appearance
        )
    }

    /// Returns `ChatMessageActionItem` for copy action.
    open func copyActionItem() -> ChatMessageActionItem {
        CopyActionItem(
            action: { [weak self] _ in
                guard let self = self else { return }

                let text: String?
                if let currentUserLang = self.channel?.membership?.language,
                   let translatedText = self.message?.translatedText(for: currentUserLang) {
                    text = translatedText
                } else {
                    text = self.message?.text
                }

                UIPasteboard.general.string = text
                self.delegate?.chatMessageActionsVCDidFinish(self)
            },
            appearance: appearance
        )
    }

    /// Returns `ChatMessageActionItem` for flag action.
    open func flagActionItem() -> ChatMessageActionItem {
        FlagActionItem(
            action: { [weak self] _ in
                guard let self = self else { return }
                self.alertsRouter.showMessageFlagConfirmationAlert { confirmed in
                    guard confirmed else { return }

                    self.messageController.flag { _ in
                        self.delegate?.chatMessageActionsVCDidFinish(self)
                    }
                }
            },
            appearance: appearance
        )
    }

    /// Triggered for actions which should be handled by `delegate` and not in this view controller.
    open func handleAction(_ actionItem: ChatMessageActionItem) {
        guard let message = message else { return }
        delegate?.chatMessageActionsVC(self, message: message, didTapOnActionItem: actionItem)
    }
}
