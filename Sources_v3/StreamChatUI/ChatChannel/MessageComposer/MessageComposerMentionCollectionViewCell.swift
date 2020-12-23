//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class MessageComposerMentionCellView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    // MARK: Properties

    open var content: (title: String, subtitle: String, userImage: UIImage?, isUserOnline: Bool)? {
        didSet {
            updateContentIfNeeded()
        }
    }

    open private(set) lazy var avatarView: AvatarView = uiConfig
        .messageComposer
        .mentionAvatarView
        .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var usernameLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints
    open private(set) lazy var usernameTagLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints
    open private(set) lazy var suggestionTypeImageView: UIImageView = UIImageView().withoutAutoresizingMaskConstraints
    private lazy var textStackView: UIStackView = UIStackView().withoutAutoresizingMaskConstraints

    // MARK: - Appearance

    override open func defaultAppearance() {
        backgroundColor = uiConfig.colorPalette.generalBackground
        usernameLabel.font = UIFont.preferredFont(forTextStyle: .footnote).bold

        usernameTagLabel.font = .preferredFont(forTextStyle: .caption1)
        usernameTagLabel.textColor = uiConfig.colorPalette.subtitleText

        usernameLabel.textColor = uiConfig.colorPalette.text
    }

    override open func setUpLayout() {
        addSubview(avatarView)
        addSubview(textStackView)
        addSubview(suggestionTypeImageView)

        setupLeftImageViewConstraints()
        setupStack()
        setupSuggestionTypeImageViewConstraints()
    }

    override open func updateContent() {
        usernameTagLabel.text = content?.subtitle
        usernameLabel.text = content?.title

        avatarView.imageView.image = content?.userImage
        suggestionTypeImageView.image = UIImage(named: "command_mention", in: .streamChatUI)
    }

    // MARK: Private

    private func setupLeftImageViewConstraints() {
        avatarView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        avatarView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        avatarView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor).isActive = true
    }

    private func setupStack() {
        textStackView.axis = .vertical
        textStackView.distribution = .equalSpacing
        textStackView.alignment = .leading

        textStackView.addArrangedSubview(usernameLabel)
        textStackView.addArrangedSubview(usernameTagLabel)
        textStackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        textStackView.leadingAnchor.constraint(
            equalToSystemSpacingAfter: avatarView.trailingAnchor,
            multiplier: 1
        ).isActive = true
    }

    private func setupSuggestionTypeImageViewConstraints() {
        suggestionTypeImageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        suggestionTypeImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
}

open class MessageComposerMentionCollectionViewCell<ExtraData: ExtraDataTypes>: UICollectionViewCell, UIConfigProvider {
    // MARK: Properties

    static var reuseId: String { String(describing: self) }

    public private(set) lazy var mentionView: MessageComposerMentionCellView<ExtraData> = {
        let view = uiConfig.messageComposer.suggestionsMentionCellView.init().withoutAutoresizingMaskConstraints
        contentView.embed(view)
        return view
    }()
}
