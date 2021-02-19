//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageReactionsVC = _ChatMessageReactionsVC<NoExtraData>

internal class _ChatMessageReactionsVC<ExtraData: ExtraDataTypes>: _ViewController, UIConfigProvider {
    internal var messageController: _ChatMessageController<ExtraData>!

    // MARK: - Subviews

    internal private(set) lazy var reactionsBubble = uiConfig
        .messageList
        .messageReactions
        .reactionsBubbleView
        .init()
        .withoutAutoresizingMaskConstraints

    // MARK: - Life Cycle

    override internal func setUp() {
        super.setUp()

        messageController.setDelegate(self)
    }

    override internal func setUpLayout() {
        view.embed(reactionsBubble)
    }

    override internal func updateContent() {
        reactionsBubble.content = messageController.message.map { message in
            let userReactionIDs = Set(message.currentUserReactions.map(\.type))

            return .init(
                style: message.isSentByCurrentUser ? .bigOutgoing : .bigIncoming,
                reactions: uiConfig.images.availableReactions
                    .keys
                    .sorted { $0.rawValue < $1.rawValue }
                    .map { .init(type: $0, isChosenByCurrentUser: userReactionIDs.contains($0)) },
                didTapOnReaction: { [weak self] in
                    self?.toggleReaction($0)
                }
            )
        }
    }

    // MARK: - Actions

    internal func toggleReaction(_ reaction: MessageReactionType) {
        guard let message = messageController.message else { return }

        let shouldRemove = message.currentUserReactions.contains { $0.type == reaction }
        shouldRemove
            ? messageController.deleteReaction(reaction)
            : messageController.addReaction(reaction)
    }
}

// MARK: - _MessageControllerDelegate

extension _ChatMessageReactionsVC: _ChatMessageControllerDelegate {
    internal func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeMessage change: EntityChange<_ChatMessage<ExtraData>>
    ) {
        switch change {
        case .create, .remove: break
        case .update: updateContentIfNeeded()
        }
    }
}
