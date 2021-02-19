//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A View that is embed inside `UICollectionViewCell`  which shows information about user which we want to tag in suggestions
internal typealias ChatMessageComposerMentionCellView = _ChatMessageComposerMentionCellView<NoExtraData>

/// A View that is embed inside `UICollectionViewCell`  which shows information about user which we want to tag in suggestions
internal class _ChatMessageComposerMentionCellView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    /// Content of the cell - `ChatUser` instance from which we take all information.
    open var content: _ChatUser<ExtraData.User>? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// `_ChatChannelAvatarView` instance which holds photo of user for tagging.
    internal private(set) lazy var avatarView: _ChatChannelAvatarView<ExtraData> = uiConfig
        .messageComposer
        .mentionAvatarView
        .init()
        .withoutAutoresizingMaskConstraints

    /// Title label which shows users whole name.
    internal private(set) lazy var usernameLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
    /// Subtitle label which shows username tag etc. `@user`.
    internal private(set) lazy var usernameTagLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
    /// ImageView which is located at the right part of the cell, showing @ symbol by default.
    internal private(set) lazy var mentionSymbolImageView: UIImageView = UIImageView().withoutAutoresizingMaskConstraints
    /// StackView which holds username and userTag labels in vertical axis by default.
    internal private(set) lazy var textStackView: UIStackView = UIStackView().withoutAutoresizingMaskConstraints

    override internal func defaultAppearance() {
        backgroundColor = uiConfig.colorPalette.popoverBackground
        usernameLabel.font = uiConfig.fonts.headlineBold

        usernameTagLabel.font = uiConfig.fonts.subheadlineBold
        usernameTagLabel.textColor = uiConfig.colorPalette.subtitleText

        usernameLabel.textColor = uiConfig.colorPalette.text

        mentionSymbolImageView.image = uiConfig.images.messageComposerCommandsMention
    }

    override internal func setUpLayout() {
        addSubview(avatarView)
        addSubview(textStackView)
        addSubview(mentionSymbolImageView)

        setupLeftImageViewConstraints()
        setupStack()
        setupmentionSymbolImageViewConstraints()
    }

    override internal func updateContent() {
        usernameLabel.text = content?.name
        if let subtitle = content?.id {
            usernameTagLabel.text = "@" + subtitle
        } else {
            usernameTagLabel.text = ""
        }

        avatarView.content = .user(user: content)
    }

    private func setupLeftImageViewConstraints() {
        avatarView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true

        avatarView.topAnchor.pin(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor).isActive = true
        avatarView.bottomAnchor.pin(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor).isActive = true

        avatarView.centerYAnchor.pin(equalTo: mentionSymbolImageView.centerYAnchor).isActive = true
        avatarView.widthAnchor.pin(equalToConstant: 40).isActive = true
        avatarView.heightAnchor.pin(equalTo: avatarView.widthAnchor).isActive = true
    }

    private func setupStack() {
        textStackView.axis = .vertical
        textStackView.distribution = .fillProportionally
        textStackView.spacing = 2
        textStackView.alignment = .leading

        textStackView.addArrangedSubview(usernameLabel)
        textStackView.addArrangedSubview(usernameTagLabel)
        textStackView.centerYAnchor.pin(equalTo: avatarView.centerYAnchor).isActive = true
        textStackView.leadingAnchor.pin(equalToSystemSpacingAfter: avatarView.trailingAnchor, multiplier: 1).isActive = true

        // We need to set both - `avatarView` and `textStackView` top and bottom anchors to
        // make this view as much flexible as possible in terms of right layout.
        // Setting those 2 constraints with low priority ensures 2 things:
        // - When avatarView height value is less than `textStackView`, `textStackView` takes over
        // expanding of the cell height according to it's height. (Both labels filled, big font)
        // - When avatarView height value is more than `textStackView`, `avatarView` takes over expanding
        // of the cell and those pinning constraints are ignored (small font / only id of user is filled in one label)
        textStackView.topAnchor.pin(equalTo: topAnchor).with(priority: .defaultLow).isActive = true
        bottomAnchor.pin(equalTo: textStackView.bottomAnchor).with(priority: .defaultLow).isActive = true

        textStackView.trailingAnchor.pin(equalTo: mentionSymbolImageView.leadingAnchor).isActive = true
        textStackView.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func setupmentionSymbolImageViewConstraints() {
        mentionSymbolImageView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        mentionSymbolImageView.centerYAnchor.pin(equalTo: centerYAnchor).isActive = true
        mentionSymbolImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
}

/// `UICollectionView` subclass which embeds inside `ChatMessageComposerMentionCellView`
internal typealias ChatMessageComposerMentionCollectionViewCell = _ChatMessageComposerMentionCollectionViewCell<NoExtraData>

/// `UICollectionView` subclass which embeds inside `ChatMessageComposerMentionCellView`
open class _ChatMessageComposerMentionCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell, UIConfigProvider {
    /// Reuse identifier for the cell used in `collectionView(cellForItem:)`
    internal class var reuseId: String { String(describing: self) }

    /// Instance of `ChatMessageComposerMentionCellView` which shows information about the mentioned user.
    internal lazy var mentionView: _ChatMessageComposerMentionCellView<ExtraData> = uiConfig
        .messageComposer
        .suggestionsMentionCellView.init()
        .withoutAutoresizingMaskConstraints

    override internal func setUpLayout() {
        super.setUpLayout()
        contentView.embed(mentionView)
    }

    // We need this method for `UICollectionViewCells` resize properly inside collectionView
    // and respect collectionView width. Without this method, the collectionViewCell content
    // autoresizes itself and ignores bounds of parent collectionView
    override open func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let preferredAttributes = super.preferredLayoutAttributesFitting(layoutAttributes)

        let targetSize = CGSize(
            width: layoutAttributes.frame.width,
            height: UIView.layoutFittingCompressedSize.height
        )

        preferredAttributes.frame.size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        return preferredAttributes
    }
}
