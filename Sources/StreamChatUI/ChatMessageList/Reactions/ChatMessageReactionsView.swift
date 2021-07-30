//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageReactionsView = _ChatMessageReactionsView<NoExtraData>

open class _ChatMessageReactionsView: _View, ThemeProvider {
    public var content: Content? {
        didSet { updateContentIfNeeded() }
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
            let itemView = components.reactionItemView.init()
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

extension _ChatMessageReactionsView {
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
