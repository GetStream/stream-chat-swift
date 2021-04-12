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

    /// The `_ChatMessageActionsView` instance for showing message's actions
    open private(set) lazy var messageActionView = _ChatMessageActionsView<ExtraData>()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()
        view.embed(messageActionView)
    }

    override open func updateContent() {
        messageActionView.content = messageActions
    }

    /// Array of `ChatMessageActionItem`s - override this to setup your own custom actions
    open var messageActions: [ChatMessageActionItem] {
        guard
            let currentUser = messageController.dataStore.currentUser(),
            let message = message,
            message.deletedAt == nil
        else { return [] }

        let editAction = EditActionItem(
            action: { [weak self] in self?.handleAction($0) },
            uiConfig: uiConfig
        )
        let deleteAction = DeleteActionItem(
            action: { [weak self] in self?.handleAction($0) },
            uiConfig: uiConfig
        )

        switch message.localState {
        case nil:
            var actions: [ChatMessageActionItem] = [
                InlineReplyActionItem(
                    action: { [weak self] in self?.handleAction($0) },
                    uiConfig: uiConfig
                ),
                ThreadReplyActionItem(
                    action: { [weak self] in self?.handleAction($0) },
                    uiConfig: uiConfig
                ),
                CopyActionItem(
                    action: { [weak self] _ in self?.handleCopyAction() },
                    uiConfig: uiConfig
                )
            ]

            if message.isSentByCurrentUser {
                actions += [editAction, deleteAction]
            } else if currentUser.mutedUsers.contains(message.author) {
                actions.append(
                    UnmuteUserActionItem(
                        action: { [weak self] _ in self?.handleUnmuteAuthorAction() },
                        uiConfig: uiConfig
                    )
                )
            } else {
                actions.append(
                    MuteUserActionItem(
                        action: { [weak self] _ in self?.handleMuteAuthorAction() },
                        uiConfig: uiConfig
                    )
                )
            }

            return actions
        case .pendingSend, .sendingFailed, .pendingSync, .syncingFailed, .deletingFailed:
            let resendAction: ChatMessageActionItem = ResendActionItem(
                action: { [weak self] _ in self?.handleResendAction() },
                uiConfig: uiConfig
            )
            return [
                message.localState == .sendingFailed ? resendAction : nil,
                editAction,
                deleteAction
            ]
            .compactMap { $0 }
        case .sending, .syncing, .deleting:
            return []
        }
    }
    
    /// Triggered when `CopyActionItem` is tapped
    open func handleCopyAction() {
        UIPasteboard.general.string = message?.text

        delegate?.didFinish(self)
    }
    
    /// Triggered for actions which should be handled by `delegate` and not in this view controller
    open func handleAction(_ actionItem: ChatMessageActionItem) {
        guard let message = message else { return }
        delegate?.didTapOnActionItem(self, message, actionItem)
    }

    /// Triggered when `DeleteActionItem` is tapped
    open func handleDeleteAction() {
        router.showMessageDeletionConfirmationAlert { confirmed in
            guard confirmed else { return }

            self.messageController.deleteMessage { _ in
                self.delegate?.didFinish(self)
            }
        }
    }

    /// Triggered when `ResendActionItem` is tapped
    open func handleResendAction() {
        messageController.resendMessage { _ in
            self.delegate?.didFinish(self)
        }
    }

    /// Triggered when `MuteActionItem` is tapped
    open func handleMuteAuthorAction() {
        guard let author = message?.author else { return }

        messageController.client
            .userController(userId: author.id)
            .mute { _ in self.delegate?.didFinish(self) }
    }

    /// Triggered when `UnmuteActionItem` is tapped
    open func handleUnmuteAuthorAction() {
        guard let author = message?.author else { return }

        messageController.client
            .userController(userId: author.id)
            .unmute { _ in self.delegate?.didFinish(self) }
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
