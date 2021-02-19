//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal protocol _ChatMessageActionsVCDelegate: AnyObject {
    associatedtype ExtraData: ExtraDataTypes

    func chatMessageActionsVC(_ vc: _ChatMessageActionsVC<ExtraData>, didTapOnInlineReplyFor message: _ChatMessage<ExtraData>)
    func chatMessageActionsVC(_ vc: _ChatMessageActionsVC<ExtraData>, didTapOnThreadReplyFor message: _ChatMessage<ExtraData>)
    func chatMessageActionsVC(_ vc: _ChatMessageActionsVC<ExtraData>, didTapOnEdit message: _ChatMessage<ExtraData>)
    func chatMessageActionsVCDidFinish(_ vc: _ChatMessageActionsVC<ExtraData>)
}

internal typealias ChatMessageActionsVC = _ChatMessageActionsVC<NoExtraData>

internal class _ChatMessageActionsVC<ExtraData: ExtraDataTypes>: _ViewController, UIConfigProvider {
    internal var messageController: _ChatMessageController<ExtraData>!
    internal var delegate: Delegate?
    internal lazy var router = uiConfig.navigation.messageActionsRouter.init(rootViewController: self)

    private var message: _ChatMessage<ExtraData>? {
        messageController.message
    }

    // MARK: - Subviews

    private lazy var messageActionView = uiConfig
        .messageList
        .messageActionsSubviews
        .actionsView
        .init()
        .withoutAutoresizingMaskConstraints

    // MARK: - Life Cycle

    override internal func setUpLayout() {
        view.embed(messageActionView)
    }

    override internal func updateContent() {
        messageActionView.actionItems = messageActions
    }

    // MARK: - Actions

    internal var messageActions: [ChatMessageActionItem<ExtraData>] {
        guard
            let currentUser = messageController.client.currentUserController().currentUser,
            let message = message,
            message.deletedAt == nil
        else { return [] }

        let editAction: ChatMessageActionItem<ExtraData> = .edit { [weak self] in self?.handleEditAction() }
        let deleteAction: ChatMessageActionItem<ExtraData> = .delete { [weak self] in self?.handleDeleteAction() }

        switch message.localState {
        case nil:
            var actions: [ChatMessageActionItem<ExtraData>] = [
                .inlineReply { [weak self] in self?.handleInlineReplyAction() },
                .threadReply { [weak self] in self?.handleThreadReplyAction() },
                .copy(
                    action: { [weak self] in self?.handleCopyAction() },
                    uiConfig: uiConfig
                )
            ]

            if message.isSentByCurrentUser {
                actions += [editAction, deleteAction]
            } else if currentUser.mutedUsers.contains(message.author) {
                actions.append(.unmuteUser { [weak self] in self?.handleUnmuteAuthorAction() })
            } else {
                actions.append(.muteUser { [weak self] in self?.handleMuteAuthorAction() })
            }

            return actions
        case .pendingSend, .sendingFailed, .pendingSync, .syncingFailed, .deletingFailed:
            return [
                message.localState == .sendingFailed ? .resend { [weak self] in self?.handleResendAction() } : nil,
                editAction,
                deleteAction
            ].compactMap { $0 }
        case .sending, .syncing, .deleting:
            return []
        }
    }

    internal func handleCopyAction() {
        UIPasteboard.general.string = message?.text

        delegate?.didFinish(self)
    }

    internal func handleInlineReplyAction() {
        guard let message = message else { return }

        delegate?.didTapOnInlineReply(self, message)
    }

    internal func handleThreadReplyAction() {
        guard let message = message else { return }

        delegate?.didTapOnThreadReply(self, message)
    }

    internal func handleEditAction() {
        guard let message = message else { return }

        delegate?.didTapOnEdit(self, message)
    }

    internal func handleDeleteAction() {
        router.showMessageDeletionConfirmationAlert { confirmed in
            guard confirmed else { return }

            self.messageController.deleteMessage { _ in
                self.delegate?.didFinish(self)
            }
        }
    }

    internal func handleResendAction() {
        messageController.resendMessage { _ in
            self.delegate?.didFinish(self)
        }
    }

    internal func handleMuteAuthorAction() {
        guard let author = message?.author else { return }

        messageController.client
            .userController(userId: author.id)
            .mute { _ in self.delegate?.didFinish(self) }
    }

    internal func handleUnmuteAuthorAction() {
        guard let author = message?.author else { return }

        messageController.client
            .userController(userId: author.id)
            .unmute { _ in self.delegate?.didFinish(self) }
    }
}

// MARK: - Delegate

internal extension _ChatMessageActionsVC {
    struct Delegate {
        internal var didTapOnInlineReply: (_ChatMessageActionsVC, _ChatMessage<ExtraData>) -> Void
        internal var didTapOnThreadReply: (_ChatMessageActionsVC, _ChatMessage<ExtraData>) -> Void
        internal var didTapOnEdit: (_ChatMessageActionsVC, _ChatMessage<ExtraData>) -> Void
        internal var didFinish: (_ChatMessageActionsVC) -> Void

        internal init(
            didTapOnInlineReply: @escaping (_ChatMessageActionsVC, _ChatMessage<ExtraData>) -> Void = { _, _ in },
            didTapOnThreadReply: @escaping (_ChatMessageActionsVC, _ChatMessage<ExtraData>) -> Void = { _, _ in },
            didTapOnEdit: @escaping (_ChatMessageActionsVC, _ChatMessage<ExtraData>) -> Void = { _, _ in },
            didFinish: @escaping (_ChatMessageActionsVC) -> Void = { _ in }
        ) {
            self.didTapOnInlineReply = didTapOnInlineReply
            self.didTapOnThreadReply = didTapOnThreadReply
            self.didTapOnEdit = didTapOnEdit
            self.didFinish = didFinish
        }

        internal init<Delegate: _ChatMessageActionsVCDelegate>(delegate: Delegate) where Delegate.ExtraData == ExtraData {
            self.init(
                didTapOnInlineReply: { [weak delegate] in delegate?.chatMessageActionsVC($0, didTapOnInlineReplyFor: $1) },
                didTapOnThreadReply: { [weak delegate] in delegate?.chatMessageActionsVC($0, didTapOnThreadReplyFor: $1) },
                didTapOnEdit: { [weak delegate] in delegate?.chatMessageActionsVC($0, didTapOnEdit: $1) },
                didFinish: { [weak delegate] in delegate?.chatMessageActionsVCDidFinish($0) }
            )
        }
    }
}
