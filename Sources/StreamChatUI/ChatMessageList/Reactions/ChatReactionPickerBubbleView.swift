//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatReactionPickerBubbleView = ChatMessageReactionsBubbleView

/// This component will be renamed to `ChatReactionPickerBubbleView` in future major versions.
open class ChatMessageReactionsBubbleView: _View, ThemeProvider {
    public var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    public private(set) lazy var contentView = components
        .reactionPickerReactionsView
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
        // We check if we have available images for the given type of reaction, if not, we hide the reaction.
        guard !(content?.reactions.compactMap { appearance.images.availableReactions[$0.type] }.isEmpty ?? false)
        else {
            isHidden = true
            return
        }

        isHidden = false
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

extension ChatMessageReactionsBubbleView {
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
