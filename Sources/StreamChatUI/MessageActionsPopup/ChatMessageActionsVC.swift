//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public protocol _ChatMessageActionsVCDelegate: AnyObject {
    associatedtype ExtraData: ExtraDataTypes

    func chatMessageActionsVC(_ vc: _ChatMessageActionsVC<ExtraData>, didTapOnInlineReplyFor message: _ChatMessage<ExtraData>)
    func chatMessageActionsVC(_ vc: _ChatMessageActionsVC<ExtraData>, didTapOnThreadReplyFor message: _ChatMessage<ExtraData>)
    func chatMessageActionsVC(_ vc: _ChatMessageActionsVC<ExtraData>, didTapOnEdit message: _ChatMessage<ExtraData>)
    func chatMessageActionsVCDidFinish(_ vc: _ChatMessageActionsVC<ExtraData>)
}

public typealias ChatMessageActionsVC = _ChatMessageActionsVC<NoExtraData>

open class _ChatMessageActionsVC<ExtraData: ExtraDataTypes>: ViewController, UIConfigProvider {
    public var messageController: _ChatMessageController<ExtraData>!
    public var delegate: Delegate? // swiftlint:disable:this weak_delegate
    public private(set) lazy var router = uiConfig.navigation.messageActionsRouter.init(rootViewController: self)

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

    override open func setUpLayout() {
        view.embed(messageActionView)
    }

    override open func updateContent() {
        messageActionView.actionItems = messageActions
    }

    // MARK: - Actions

    open var messageActions: [ChatMessageActionItem] {
        guard
            let currentUser = messageController.client.currentUserController().currentUser,
            let message = message,
            message.deletedAt == nil
        else { return [] }

        let editAction: ChatMessageActionItem = .edit { [weak self] in self?.handleEditAction() }
        let deleteAction: ChatMessageActionItem = .delete { [weak self] in self?.handleDeleteAction() }

        switch message.localState {
        case nil:
            var actions: [ChatMessageActionItem] = [
                .inlineReply { [weak self] in self?.handleInlineReplyAction() },
                .threadReply { [weak self] in self?.handleThreadReplyAction() },
                .copy { [weak self] in self?.handleCopyAction() }
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

    open func handleCopyAction() {
        UIPasteboard.general.string = message?.text

        delegate?.didFinish(self)
    }

    open func handleInlineReplyAction() {
        guard let message = message else { return }

        delegate?.didTapOnInlineReply(self, message)
    }

    open func handleThreadReplyAction() {
        guard let message = message else { return }

        delegate?.didTapOnThreadReply(self, message)
    }

    open func handleEditAction() {
        guard let message = message else { return }

        delegate?.didTapOnEdit(self, message)
    }

    open func handleDeleteAction() {
        router.showMessageDeletionConfirmationAlert { confirmed in
            guard confirmed else { return }

            self.messageController.deleteMessage { _ in
                self.delegate?.didFinish(self)
            }
        }
    }

    open func handleResendAction() {
        messageController.resendMessage { _ in
            self.delegate?.didFinish(self)
        }
    }

    open func handleMuteAuthorAction() {
        guard let author = message?.author else { return }

        messageController.client
            .userController(userId: author.id)
            .mute { _ in self.delegate?.didFinish(self) }
    }

    open func handleUnmuteAuthorAction() {
        guard let author = message?.author else { return }

        messageController.client
            .userController(userId: author.id)
            .unmute { _ in self.delegate?.didFinish(self) }
    }
}

// MARK: - Delegate

extension _ChatMessageActionsVC {
    public struct Delegate {
        public var didTapOnInlineReply: (_ChatMessageActionsVC, _ChatMessage<ExtraData>) -> Void
        public var didTapOnThreadReply: (_ChatMessageActionsVC, _ChatMessage<ExtraData>) -> Void
        public var didTapOnEdit: (_ChatMessageActionsVC, _ChatMessage<ExtraData>) -> Void
        public var didFinish: (_ChatMessageActionsVC) -> Void

        public init(
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

        public init<Delegate: _ChatMessageActionsVCDelegate>(delegate: Delegate) where Delegate.ExtraData == ExtraData {
            self.init(
                didTapOnInlineReply: { [weak delegate] in delegate?.chatMessageActionsVC($0, didTapOnInlineReplyFor: $1) },
                didTapOnThreadReply: { [weak delegate] in delegate?.chatMessageActionsVC($0, didTapOnThreadReplyFor: $1) },
                didTapOnEdit: { [weak delegate] in delegate?.chatMessageActionsVC($0, didTapOnEdit: $1) },
                didFinish: { [weak delegate] in delegate?.chatMessageActionsVCDidFinish($0) }
            )
        }
    }
}
