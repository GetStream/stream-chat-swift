//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A View that is embed inside `UICollectionViewCell`  which shows information about user which we want to tag in suggestions
public typealias ChatMentionSuggestionView = _ChatMentionSuggestionView<NoExtraData>

/// A View that is embed inside `UICollectionViewCell`  which shows information about user which we want to tag in suggestions
open class _ChatMentionSuggestionView<ExtraData: ExtraDataTypes>: _View, ThemeProvider {
    /// Content of the cell - `ChatUser` instance from which we take all information.
    open var content: _ChatUser<ExtraData.User>? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// `_ChatChannelAvatarView` instance which holds photo of user for tagging.
    open private(set) lazy var avatarView: _ChatUserAvatarView<ExtraData> = components
        .mentionAvatarView
        .init()
        .withoutAutoresizingMaskConstraints

    /// Title label which shows users whole name.
    open private(set) lazy var usernameLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
    /// Subtitle label which shows username tag etc. `@user`.
    open private(set) lazy var usernameTagLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
    /// ImageView which is located at the right part of the cell, showing @ symbol by default.
    open private(set) lazy var mentionSymbolImageView: UIImageView = UIImageView().withoutAutoresizingMaskConstraints
    /// StackView which holds username and userTag labels in vertical axis by default.
    open private(set) lazy var textStackView: UIStackView = UIStackView().withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = appearance.colorPalette.popoverBackground
        usernameLabel.font = appearance.fonts.headlineBold

        usernameTagLabel.font = appearance.fonts.subheadlineBold
        usernameTagLabel.textColor = appearance.colorPalette.subtitleText

        usernameLabel.textColor = appearance.colorPalette.text

        mentionSymbolImageView.image = appearance.images.commandMention
    }

    override open func setUpLayout() {
        addSubview(avatarView)
        addSubview(textStackView)
        addSubview(mentionSymbolImageView)

        setupLeftImageViewConstraints()
        setupStack()
        setupmentionSymbolImageViewConstraints()
    }

    override open func updateContent() {
        usernameLabel.text = content?.name
        if let subtitle = content?.id {
            usernameTagLabel.text = "@" + subtitle
        } else {
            usernameTagLabel.text = ""
        }

        avatarView.content = content
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
