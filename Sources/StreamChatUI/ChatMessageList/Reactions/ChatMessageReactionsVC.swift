//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Controller for the message reactions picker as a list of toggles
open class ChatMessageReactionsVC: _ViewController, ThemeProvider, ChatMessageControllerDelegate {
    public var messageController: ChatMessageController!

    // MARK: - Subviews

    open func reactionsBubbleClass() -> ChatMessageReactionsBubbleView.Type {
        components.reactionsBubbleView
    }

    public private(set) lazy var reactionsBubble = reactionsBubbleClass()
        .init()
        .withoutAutoresizingMaskConstraints

    // MARK: - Life Cycle

    override open func setUp() {
        super.setUp()
        messageController.delegate = self
    }

    override open func setUpLayout() {
        view.embed(reactionsBubble)
    }

    override open func updateContent() {
        reactionsBubble.content = messageController.message.map { message in
            let userReactionIDs = Set(message.currentUserReactions.map(\.type))

            return .init(
                style: message.isSentByCurrentUser ? .bigOutgoing : .bigIncoming,
                reactions: appearance.images.availableReactions
                    .keys
                    .sorted { $0.rawValue < $1.rawValue }
                    .map {
                        .init(
                            type: $0,
                            score: message.reactionScores[$0] ?? 0,
                            isChosenByCurrentUser: userReactionIDs.contains($0)
                        )
                    },
                didTapOnReaction: { [weak self] in
                    self?.toggleReaction($0)
                }
            )
        }
    }

    // MARK: - Actions

    open func toggleReaction(_ reaction: MessageReactionType) {
        guard let message = messageController.message else { return }
        
        let completion: (Error?) -> Void = { [weak self] _ in
            self?.dismiss(animated: true)
        }

        let shouldRemove = message.currentUserReactions.contains { $0.type == reaction }
        shouldRemove
            ? messageController.deleteReaction(reaction, completion: completion)
            : messageController.addReaction(reaction, completion: completion)
    }
    
    // MARK: - MessageControllerDelegate
    
    open func messageController(
        _ controller: ChatMessageController,
        didChangeMessage change: EntityChange<ChatMessage>
    ) {
        switch change {
        case .create, .remove: break
        case .update: updateContentIfNeeded()
        }
    }
}
