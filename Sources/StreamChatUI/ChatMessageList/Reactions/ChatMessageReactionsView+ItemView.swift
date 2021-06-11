//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension _ChatMessageReactionsView {
    internal class ItemView: _Button, UIConfigProvider {
        internal var content: Content? {
            didSet { updateContentIfNeeded() }
        }

        // MARK: - Overrides

        override internal var intrinsicContentSize: CGSize {
            reactionImage?.size ?? .zero
        }

        override internal func setUp() {
            super.setUp()

            addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        }

        override internal func updateContent() {
            setImage(reactionImage, for: .normal)
            imageView?.tintColor = reactionImageTint
        }

        override internal func tintColorDidChange() {
            super.tintColorDidChange()

            updateContentIfNeeded()
        }

        // MARK: - Actions

        @objc internal func handleTap() {
            guard let content = self.content else { return }

            content.onTap(content.reaction.type)
        }
    }
}

// MARK: - Content

extension _ChatMessageReactionsView.ItemView {
    internal struct Content {
        internal let useBigIcon: Bool
        internal let reaction: ChatMessageReactionData
        internal var onTap: (MessageReactionType) -> Void

        internal init(
            useBigIcon: Bool,
            reaction: ChatMessageReactionData,
            onTap: @escaping (MessageReactionType) -> Void
        ) {
            self.useBigIcon = useBigIcon
            self.reaction = reaction
            self.onTap = onTap
        }
    }
}

// MARK: - Private

private extension _ChatMessageReactionsView.ItemView {
    var reactionImage: UIImage? {
        guard let content = content else { return nil }

        let appearance = uiConfig.images.availableReactions[content.reaction.type]

        return content.useBigIcon ?
            appearance?.largeIcon :
            appearance?.smallIcon
    }

    var reactionImageTint: UIColor? {
        guard let content = content else { return nil }

        return content.reaction.isChosenByCurrentUser ?
            tintColor :
            uiConfig.colorPalette.inactiveTint
    }
}
