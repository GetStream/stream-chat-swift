//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// `UICollectionViewCell` for the reaction's author view.
open class ChatMessageReactionAuthorViewCell: _CollectionViewCell, ThemeProvider {
    open class var reuseId: String { String(describing: self) }

    /// The reaction of a message.
    open var reaction: ChatMessageReaction? {
        didSet { updateContentIfNeeded() }
    }

    open lazy var containerStack = ContainerStackView(
        axis: .vertical,
        alignment: .center,
        spacing: 4,
        distribution: .natural
    ).withoutAutoresizingMaskConstraints

    open lazy var authorAvatarView: ChatAvatarView = components
        .avatarView.init()
        .withoutAutoresizingMaskConstraints

    open lazy var authorNameLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory

    /// The size of the avatar view that belongs to the author of the reaction.
    open var authorAvatarSize: CGSize { .init(width: 64, height: 64) }

    override open func setUpAppearance() {
        super.setUpAppearance()

        authorNameLabel.font = appearance.fonts.footnoteBold
        authorNameLabel.textAlignment = .center
        authorNameLabel.numberOfLines = 0
        authorNameLabel.lineBreakMode = .byClipping
        authorNameLabel.adjustsFontSizeToFitWidth = true
    }

    override open func setUpLayout() {
        super.setUpLayout()

        contentView.embed(containerStack)
        containerStack.addArrangedSubview(authorAvatarView)
        containerStack.addArrangedSubview(authorNameLabel)

        NSLayoutConstraint.activate([
            authorAvatarView.widthAnchor.pin(equalToConstant: authorAvatarSize.width),
            authorAvatarView.heightAnchor.pin(equalToConstant: authorAvatarSize.height),
            authorNameLabel.widthAnchor.pin(equalTo: authorAvatarView.widthAnchor)
        ])
    }

    override open func updateContent() {
        super.updateContent()

        let placeholder = appearance.images.userAvatarPlaceholder1
        components.imageLoader.loadImage(
            into: authorAvatarView.imageView,
            url: reaction?.author.imageURL,
            imageCDN: components.imageCDN,
            placeholder: placeholder,
            preferredSize: authorAvatarSize
        )

        authorNameLabel.text = reaction?.author.name
    }
}
