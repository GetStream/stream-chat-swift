//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    /// `ChatMessageActionsVC.Delegate` instance.
    public var delegate: Delegate?

    /// `ChatMessageController` instance used to obtain the message data.
    public var messageController: ChatMessageController!

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
    
    /// Class used for buttons in `messageActionsContainerView`.
    open var actionButtonClass: ChatMessageActionControl.Type { ChatMessageActionControl.self }

    override open func setUpLayout() {
        super.setUpLayout()
        
        messageActionsContainerStackView.axis = .vertical
        messageActionsContainerStackView.alignment = .fill
        messageActionsContainerStackView.spacing = 1
        view.embed(messageActionsContainerStackView)
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        messageActionsContainerStackView.layer.cornerRadius = 16
        messageActionsContainerStackView.layer.masksToBounds = true
        messageActionsContainerStackView.backgroundColor = appearance.colorPalette.border
    }

    override open func updateContent() {
        messageActionsContainerStackView.subviews.forEach {
            messageActionsContainerStackView.removeArrangedSubview($0)
        }

        messageActions.forEach {
            let actionView = actionButtonClass.init()
            actionView.containerStackView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            actionView.content = $0
            messageActionsContainerStackView.addArrangedSubview(actionView)
        }
    }

    /// Array of `ChatMessageActionItem`s - override this to setup your own custom actions
    open var messageActions: [ChatMessageActionItem] {
        guard
            let currentUser = messageController.dataStore.currentUser(),
            let message = message,
            message.isDeleted == false
        else { return [] }

        switch message.localState {
        case nil:
            var actions: [ChatMessageActionItem] = [
                inlineReplyActionItem()
            ]

            if channelConfig.repliesEnabled && !message.isPartOfThread {
                actions.append(threadReplyActionItem())
            }

            actions.append(copyActionItem())

            if message.isSentByCurrentUser {
                actions += [editActionItem(), deleteActionItem()]
            } else if currentUser.mutedUsers.contains(message.author) {
                actions.append(
                    unmuteActionItem()
                )
            } else {
                actions.append(
                    muteActionItem()
                )
            }

            return actions
        case .pendingSend, .sendingFailed, .pendingSync, .syncingFailed, .deletingFailed:
            return [
                message.localState == .sendingFailed ? resendActionItem() : nil,
                editActionItem(),
                deleteActionItem()
            ]
            .compactMap { $0 }
        case .sending, .syncing, .deleting:
            return []
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
                        self.delegate?.didFinish(self)
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
                    self.delegate?.didFinish(self)
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
                    .mute { _ in self.delegate?.didFinish(self) }
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
                    .unmute { _ in self.delegate?.didFinish(self) }
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
    
    /// Returns `ChatMessageActionItem` for copy action.
    open func copyActionItem() -> ChatMessageActionItem {
        CopyActionItem(
            action: { [weak self] _ in
                guard let self = self else { return }
                UIPasteboard.general.string = self.message?.text

                self.delegate?.didFinish(self)
            },
            appearance: appearance
        )
    }

    /// Triggered for actions which should be handled by `delegate` and not in this view controller.
    open func handleAction(_ actionItem: ChatMessageActionItem) {
        guard let message = message else { return }
        delegate?.didTapOnActionItem(self, message, actionItem)
    }
}

// MARK: - Delegate

public extension ChatMessageActionsVC {
    /// Delegate instance for `ChatMessageActionsVC`.
    struct Delegate {
        /// Triggered when action item was tapped.
        /// You can decide what to do with message based on which instance of `ChatMessageActionItem` you received.
        public var didTapOnActionItem: (ChatMessageActionsVC, ChatMessage, ChatMessageActionItem) -> Void
        /// Triggered when `_ChatMessageActionsVC` should be dismissed.
        public var didFinish: (ChatMessageActionsVC) -> Void

        /// Init of `ChatMessageActionsVC.Delegate`.
        public init(
            didTapOnActionItem: @escaping (ChatMessageActionsVC, ChatMessage, ChatMessageActionItem)
                -> Void = { _, _, _ in },
            didFinish: @escaping (ChatMessageActionsVC) -> Void = { _ in }
        ) {
            self.didTapOnActionItem = didTapOnActionItem
            self.didFinish = didFinish
        }

        /// Wraps `ChatMessageActionsVCDelegate` into `_ChatMessageActionsVC.Delegate`.
        public init<Delegate: ChatMessageActionsVCDelegate>(delegate: Delegate) {
            self.init(
                didTapOnActionItem: { [weak delegate] in delegate?.chatMessageActionsVC($0, message: $1, didTapOnActionItem: $2) },
                didFinish: { [weak delegate] in delegate?.chatMessageActionsVCDidFinish($0) }
            )
        }
    }
}
