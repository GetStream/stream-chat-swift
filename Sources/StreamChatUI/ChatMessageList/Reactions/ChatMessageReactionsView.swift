//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view that shows the list of reactions attached to the message.
open class ChatMessageReactionsView: _View, ThemeProvider {
    public var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    open var reactionItemView: ChatMessageReactionItemView.Type {
        components.messageReactionItemView
    }

    // returns the selection of reactions that should be rendered by this view
    open var reactions: [ChatMessageReactionData] {
        guard let content = content else { return [] }
        return content.reactions.filter { reaction in
            guard appearance.images.availableReactions[reaction.type] != nil else {
                log
                    .warning(
                        "reaction with type \(reaction.type) is not registered in appearance.images.availableReactions, skipping"
                    )
                return false
            }
            return true
        }
    }

    // MARK: - Subviews

    public private(set) lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = UIStackView.spacingUseSystem
        return stack.withoutAutoresizingMaskConstraints
    }()

    // MARK: - Overrides

    override open func setUpLayout() {
        embed(stackView)
    }

    override open func updateContent() {
        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }

        guard let content = content else { return }

        content.reactions.forEach { reaction in
            if appearance.images.availableReactions[reaction.type] == nil {
                log
                    .warning(
                        "reaction with type \(reaction.type) is not registered in appearance.images.availableReactions, skipping"
                    )
                return
            }
            let itemView = reactionItemView.init()
            itemView.content = .init(
                useBigIcon: content.useBigIcons,
                reaction: reaction,
                onTap: content.didTapOnReaction
            )
            stackView.addArrangedSubview(itemView)
        }
    }
}

// MARK: - Content

extension ChatMessageReactionsView {
    public struct Content {
        public let useBigIcons: Bool
        public let reactions: [ChatMessageReactionData]
        public let didTapOnReaction: ((MessageReactionType) -> Void)?

        public init(
            useBigIcons: Bool,
            reactions: [ChatMessageReactionData],
            didTapOnReaction: ((MessageReactionType) -> Void)?
        ) {
            self.useBigIcons = useBigIcons
            self.reactions = reactions
            self.didTapOnReaction = didTapOnReaction
        }
    }
}
