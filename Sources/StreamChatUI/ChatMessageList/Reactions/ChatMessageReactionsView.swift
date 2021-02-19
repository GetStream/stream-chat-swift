//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageReactionsView = _ChatMessageReactionsView<NoExtraData>

internal class _ChatMessageReactionsView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    internal var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    internal private(set) lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = UIStackView.spacingUseSystem
        return stack.withoutAutoresizingMaskConstraints
    }()

    // MARK: - Overrides

    override internal func setUpLayout() {
        embed(stackView)
    }

    override internal func updateContent() {
        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }

        guard let content = content else { return }

        content.reactions.forEach { reaction in
            let itemView = uiConfig.messageList.messageReactions.reactionItemView.init()
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
    internal struct Content {
        internal let useBigIcons: Bool
        internal let reactions: [ChatMessageReactionData]
        internal let didTapOnReaction: (MessageReactionType) -> Void

        internal init(
            useBigIcons: Bool,
            reactions: [ChatMessageReactionData],
            didTapOnReaction: @escaping (MessageReactionType) -> Void
        ) {
            self.useBigIcons = useBigIcons
            self.reactions = reactions
            self.didTapOnReaction = didTapOnReaction
        }
    }
}
