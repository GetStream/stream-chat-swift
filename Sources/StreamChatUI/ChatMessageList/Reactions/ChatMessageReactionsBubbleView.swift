//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageReactionsBubbleView = _ChatMessageReactionsBubbleView<NoExtraData>

internal class _ChatMessageReactionsBubbleView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    internal var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    internal private(set) lazy var contentView = uiConfig
        .messageList
        .messageReactions
        .reactionsView
        .init()
        .withoutAutoresizingMaskConstraints

    internal var tailLeadingAnchor: NSLayoutXAxisAnchor { contentView.centerXAnchor }
    internal var tailTrailingAnchor: NSLayoutXAxisAnchor { contentView.centerXAnchor }

    // MARK: - Overrides

    override internal func setUpLayout() {
        super.setUpLayout()

        embed(contentView)
    }

    // MARK: - Life Cycle

    override internal func updateContent() {
        contentView.content = content.flatMap {
            .init(
                useBigIcons: $0.style.isBig,
                reactions: $0.reactions,
                didTapOnReaction: $0.didTapOnReaction
            )
        }
    }
}

// MARK: - Content

extension _ChatMessageReactionsBubbleView {
    internal struct Content {
        internal let style: ChatMessageReactionsBubbleStyle
        internal let reactions: [ChatMessageReactionData]
        internal let didTapOnReaction: (MessageReactionType) -> Void

        internal init(
            style: ChatMessageReactionsBubbleStyle,
            reactions: [ChatMessageReactionData],
            didTapOnReaction: @escaping (MessageReactionType) -> Void
        ) {
            self.style = style
            self.reactions = reactions
            self.didTapOnReaction = didTapOnReaction
        }
    }
}
