//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageReactionVC<ExtraData: ExtraDataTypes>: ViewController, UIConfigProvider {
    public var messageController: _ChatMessageController<ExtraData>!

    // MARK: - Subviews

    public private(set) lazy var reactionsBubble = uiConfig
        .messageList
        .messageReactions
        .reactionsBubbleView
        .init()
        .withoutAutoresizingMaskConstraints

    // MARK: - Life Cycle

    override open func setUp() {
        super.setUp()

        messageController.setDelegate(self)
    }

    override open func setUpLayout() {
        view.embed(reactionsBubble)
    }

    override open func updateContent() {
        reactionsBubble.content = messageController.message.map { message in
            let userReactionIDs = Set(message.currentUserReactions.map(\.type))
            let availableReactions = uiConfig.messageList.messageReactions.availableReactions

            return .init(
                style: message.isSentByCurrentUser ? .bigOutgoing : .bigIncoming,
                reactions: availableReactions
                    .sorted { $0.rawValue < $1.rawValue }
                    .map { .init(type: $0, isChosenByCurrentUser: userReactionIDs.contains($0)) },
                didTapOnReaction: { [weak self] in
                    self?.toggleReaction($0)
                }
            )
        }
    }

    // MARK: - Actions

    public func toggleReaction(_ reaction: MessageReactionType) {
        guard let message = messageController.message else { return }

        let shouldRemove = message.currentUserReactions.contains { $0.type == reaction }
        shouldRemove
            ? messageController.deleteReaction(reaction)
            : messageController.addReaction(reaction)
    }
}

// MARK: - _MessageControllerDelegate

extension ChatMessageReactionVC: _MessageControllerDelegate {
    public func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeMessage change: EntityChange<_ChatMessage<ExtraData>>
    ) {
        switch change {
        case .create, .remove: break
        case .update: updateContentIfNeeded()
        }
    }
}
