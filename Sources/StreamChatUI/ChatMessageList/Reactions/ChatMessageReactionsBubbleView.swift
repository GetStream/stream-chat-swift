//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageReactionsBubbleView = _ChatMessageReactionsBubbleView<NoExtraData>

open class _ChatMessageReactionsBubbleView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    public var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    public private(set) lazy var contentView = uiConfig
        .messageList
        .messageReactions
        .reactionsView
        .init()
        .withoutAutoresizingMaskConstraints

    open var tailLeadingAnchor: NSLayoutXAxisAnchor { contentView.centerXAnchor }
    open var tailTrailingAnchor: NSLayoutXAxisAnchor { contentView.centerXAnchor }

    // MARK: - Overrides

    override open func setUpLayout() {
        super.setUpLayout()

        embed(contentView)
    }

    // MARK: - Life Cycle

    override open func updateContent() {
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
    public struct Content {
        public let style: ChatMessageReactionsBubbleStyle
        public let reactions: [ChatMessageReactionData]
        public let didTapOnReaction: (MessageReactionType) -> Void

        public init(
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
