//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view that renders a single reaction view button.
open class ChatMessageReactionItemView: _Button, AppearanceProvider {
    public struct Content {
        public let useBigIcon: Bool
        public let reaction: ChatMessageReactionData
        public var onTap: ((MessageReactionType) -> Void)?

        public init(
            useBigIcon: Bool,
            reaction: ChatMessageReactionData,
            onTap: ((MessageReactionType) -> Void)?
        ) {
            self.useBigIcon = useBigIcon
            self.reaction = reaction
            self.onTap = onTap
        }
    }

    public var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    override open var intrinsicContentSize: CGSize {
        image(for: .normal)?.size ?? super.intrinsicContentSize
    }

    open var reactionImage: UIImage? {
        guard let content = content else { return nil }

        let reactions = appearance.images.availableReactions[content.reaction.type]

        return content.useBigIcon ?
            reactions?.largeIcon :
            reactions?.smallIcon
    }

    open var reactionImageTint: UIColor? {
        guard let content = content else { return nil }

        return content.reaction.isChosenByCurrentUser ?
            tintColor :
            appearance.colorPalette.inactiveTint
    }

    // MARK: - Overrides

    override open func setUp() {
        super.setUp()

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        setContentCompressionResistancePriority(.streamRequire, for: .vertical)
        setContentCompressionResistancePriority(.streamRequire, for: .horizontal)
    }

    override open func updateContent() {
        super.updateContent()

        setImage(reactionImage, for: .normal)
        imageView?.tintColor = reactionImageTint
        isUserInteractionEnabled = content?.onTap != nil
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()

        updateContentIfNeeded()
    }

    // MARK: - Actions

    @objc open func handleTap() {
        guard let content = self.content else { return }

        content.onTap?(content.reaction.type)
    }
}
