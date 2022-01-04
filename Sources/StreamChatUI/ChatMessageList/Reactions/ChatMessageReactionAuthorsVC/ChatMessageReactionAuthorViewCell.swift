//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// `UICollectionViewCell` for the reaction's author view.
open class ChatMessageReactionAuthorViewCell: _CollectionViewCell, ThemeProvider {
    open class var reuseId: String { String(describing: self) }

    /// The content of reaction author view cell.
    public struct Content {
        /// The reaction of the message.
        public var reaction: ChatMessageReaction
        /// The id of the current logged in user.
        public var currentUserId: UserId

        public init(
            reaction: ChatMessageReaction,
            currentUserId: UserId
        ) {
            self.reaction = reaction
            self.currentUserId = currentUserId
        }
    }

    /// The content of reaction author view cell.
    open var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The container stack that composes the author avatar view and the author name label.
    open lazy var containerStack = ContainerStackView().withoutAutoresizingMaskConstraints

    /// The author's avatar view.
    open lazy var authorAvatarView: ChatAvatarView = components
        .avatarView.init()
        .withoutAutoresizingMaskConstraints

    /// The author's name label.
    open lazy var authorNameLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory

    /// The bubble view around the message reaction.
    open lazy var reactionBubbleView: ChatReactionBubbleBaseView = components
        .messageReactionsBubbleView.init()
        .withoutAutoresizingMaskConstraints

    /// The reaction view inside the reaction bubble.
    public lazy var reactionItemView: ChatMessageReactionItemView = components
        .messageReactionItemView.init()
        .withoutAutoresizingMaskConstraints

    /// The constraint that if active renders the reaction in the leading side of the avatar view.
    public var reactionLeadingConstraint: NSLayoutConstraint?

    /// The constraint that if active renders the reaction in the trailing side of the avatar view.
    public var reactionTrailingConstraint: NSLayoutConstraint?

    /// The size of the avatar view that belongs to the author of the reaction.
    open var authorAvatarSize: CGSize { .init(width: 64, height: 64) }

    override open func setUpAppearance() {
        super.setUpAppearance()

        authorNameLabel.font = appearance.fonts.footnoteBold
        authorNameLabel.textAlignment = .center
        authorNameLabel.numberOfLines = 2
        authorNameLabel.adjustsFontSizeToFitWidth = true
    }

    override open func setUpLayout() {
        super.setUpLayout()

        containerStack.axis = .vertical
        containerStack.alignment = .top
        containerStack.spacing = 8
        containerStack.distribution = .natural

        contentView.addSubview(containerStack)
        NSLayoutConstraint.activate([
            containerStack.leadingAnchor.pin(equalTo: contentView.leadingAnchor),
            containerStack.trailingAnchor.pin(equalTo: contentView.trailingAnchor),
            containerStack.topAnchor.pin(equalTo: contentView.topAnchor)
        ])

        containerStack.addArrangedSubview(authorAvatarView)
        containerStack.addArrangedSubview(authorNameLabel)
        authorAvatarView.addSubview(reactionBubbleView)

        reactionBubbleView.addSubview(reactionItemView)
        reactionItemView.pin(to: reactionBubbleView.layoutMarginsGuide)

        NSLayoutConstraint.activate([
            authorAvatarView.widthAnchor.pin(equalToConstant: authorAvatarSize.width),
            authorAvatarView.heightAnchor.pin(equalToConstant: authorAvatarSize.height),
            authorNameLabel.widthAnchor.pin(equalTo: authorAvatarView.widthAnchor),
            reactionBubbleView.bottomAnchor.pin(equalTo: authorAvatarView.bottomAnchor)
        ])

        reactionTrailingConstraint = reactionBubbleView.rightAnchor.pin(equalTo: authorAvatarView.centerXAnchor)
        reactionLeadingConstraint = reactionBubbleView.leftAnchor.pin(equalTo: authorAvatarView.centerXAnchor)

        reactionTrailingConstraint?.isActive = false
        reactionLeadingConstraint?.isActive = false
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else {
            reactionItemView.content = nil
            authorNameLabel.text = nil
            authorAvatarView.imageView.image = nil
            return
        }

        let placeholder = appearance.images.userAvatarPlaceholder1
        components.imageLoader.loadImage(
            into: authorAvatarView.imageView,
            url: content.reaction.author.imageURL,
            imageCDN: components.imageCDN,
            placeholder: placeholder,
            preferredSize: authorAvatarSize
        )

        let reactionAuthor = content.reaction.author
        let isCurrentUser = content.currentUserId == reactionAuthor.id

        authorNameLabel.text = isCurrentUser ? L10n.Reaction.Authors.Cell.you : reactionAuthor.name

        reactionBubbleView.tailDirection = isCurrentUser ? .toTrailing : .toLeading
        reactionItemView.content = .init(
            useBigIcon: false,
            reaction: ChatMessageReactionData(
                type: content.reaction.type,
                score: content.reaction.score,
                isChosenByCurrentUser: isCurrentUser
            ),
            onTap: nil
        )

        reactionTrailingConstraint?.isActive = isCurrentUser
        reactionLeadingConstraint?.isActive = !isCurrentUser
    }
}
