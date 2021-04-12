//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public protocol _ChatMessageActionsVCDelegate: AnyObject {
    associatedtype ExtraData: ExtraDataTypes

    func chatMessageActionsVC(
        _ vc: _ChatMessageActionsVC<ExtraData>,
        message: _ChatMessage<ExtraData>,
        didTapOnActionItem actionItem: ChatMessageActionItem
    )
    func chatMessageActionsVCDidFinish(_ vc: _ChatMessageActionsVC<ExtraData>)
}

public typealias ChatMessageActionsVC = _ChatMessageActionsVC<NoExtraData>

/// View controller to show message actions
open class _ChatMessageActionsVC<ExtraData: ExtraDataTypes>: _ViewController, UIConfigProvider {
    /// `_ChatMessageController` instance used to obtain current data
    public var messageController: _ChatMessageController<ExtraData>!
    /// `_ChatMessageActionsVC.Delegate` instance
    public var delegate: Delegate?

    /// Message that should be shown in this view controller
    open var message: _ChatMessage<ExtraData>? {
        messageController.message
    }
    
    /// The `_ChatMessageActionsRouter` instance responsible for navigation.
    open private(set) lazy var router = uiConfig
        .navigation
        .messageActionsRouter
        .init(rootViewController: self)

    /// `ContainerView` for showing message's actions.
    open private(set) lazy var messageActionsContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    /// Class used for buttons in `messageActionsContainerView`.
    open var actionButtonClass: _ChatMessageActionControl<ExtraData>.Type { _ChatMessageActionControl<ExtraData>.self }

    override open func setUpLayout() {
        super.setUpLayout()
        
        messageActionsContainerStackView.axis = .vertical
        messageActionsContainerStackView.alignment = .fill
        messageActionsContainerStackView.spacing = 1
        view.embed(messageActionsContainerStackView)
    }
    
    override public func defaultAppearance() {
        super.defaultAppearance()
        
        messageActionsContainerStackView.layer.cornerRadius = 16
        messageActionsContainerStackView.layer.masksToBounds = true
        messageActionsContainerStackView.backgroundColor = uiConfig.colorPalette.border
    }

    override open func updateContent() {
        messageActionsContainerStackView.subviews.forEach {
            messageActionsContainerStackView.removeArrangedSubview($0)
        }

        messageActions.forEach {
            let actionView = actionButtonClass.init()
            actionView.content = $0
            messageActionsContainerStackView.addArrangedSubview(actionView)
        }
    }

    /// Array of `ChatMessageActionItem`s - override this to setup your own custom actions
    open var messageActions: [ChatMessageActionItem] {
        guard
            let currentUser = messageController.dataStore.currentUser(),
            let message = message,
            message.deletedAt == nil
        else { return [] }

        switch message.localState {
        case nil:
            var actions: [ChatMessageActionItem] = [
                inlineReplyActionItem(),
                threadReplyActionItem(),
                copyActionItem()
            ]

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
            uiConfig: uiConfig
        )
    }
    
    /// Returns `ChatMessageActionItem` for delete action
    open func deleteActionItem() -> ChatMessageActionItem {
        DeleteActionItem(
            action: { [weak self] _ in
                guard let self = self else { return }
                self.router.showMessageDeletionConfirmationAlert { confirmed in
                    guard confirmed else { return }

                    self.messageController.deleteMessage { _ in
                        self.delegate?.didFinish(self)
                    }
                }
            },
            uiConfig: uiConfig
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
            uiConfig: uiConfig
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
            uiConfig: uiConfig
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
            uiConfig: uiConfig
        )
    }
    
    /// Returns `ChatMessageActionItem` for inline reply action.
    open func inlineReplyActionItem() -> ChatMessageActionItem {
        InlineReplyActionItem(
            action: { [weak self] in self?.handleAction($0) },
            uiConfig: uiConfig
        )
    }
    
    /// Returns `ChatMessageActionItem` for thread reply action.
    open func threadReplyActionItem() -> ChatMessageActionItem {
        ThreadReplyActionItem(
            action: { [weak self] in self?.handleAction($0) },
            uiConfig: uiConfig
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
            uiConfig: uiConfig
        )
    }

    /// Triggered for actions which should be handled by `delegate` and not in this view controller.
    open func handleAction(_ actionItem: ChatMessageActionItem) {
        guard let message = message else { return }
        delegate?.didTapOnActionItem(self, message, actionItem)
    }
}

// MARK: - Delegate

public extension _ChatMessageActionsVC {
    /// Delegate instance for `_ChatMessageActionsVC`
    struct Delegate {
        /// Triggered when action item was tapped
        /// You can decide what to do with message based on which instance of `ChatMessageActionItem` you received
        public var didTapOnActionItem: (_ChatMessageActionsVC, _ChatMessage<ExtraData>, ChatMessageActionItem) -> Void
        /// Triggered when `_ChatMessageActionsVC` should be dismissed
        public var didFinish: (_ChatMessageActionsVC) -> Void

        /// Init of `_ChatMessageActionsVC.Delegate`
        public init(
            didTapOnActionItem: @escaping (_ChatMessageActionsVC, _ChatMessage<ExtraData>, ChatMessageActionItem)
                -> Void = { _, _, _ in },
            didFinish: @escaping (_ChatMessageActionsVC) -> Void = { _ in }
        ) {
            self.didTapOnActionItem = didTapOnActionItem
            self.didFinish = didFinish
        }

        /// Wraps `_ChatMessageActionsVCDelegate` into `_ChatMessageActionsVC.Delegate`
        public init<Delegate: _ChatMessageActionsVCDelegate>(delegate: Delegate) where Delegate.ExtraData == ExtraData {
            self.init(
                didTapOnActionItem: { [weak delegate] in delegate?.chatMessageActionsVC($0, message: $1, didTapOnActionItem: $2) },
                didFinish: { [weak delegate] in delegate?.chatMessageActionsVCDidFinish($0) }
            )
        }
    }
}
