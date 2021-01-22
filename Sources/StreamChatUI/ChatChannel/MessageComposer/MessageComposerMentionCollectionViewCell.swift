//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class MessageComposerMentionCellView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    // MARK: Properties

    open var content: (title: String, subtitle: String, imageURL: URL?, isUserOnline: Bool)? {
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

    override public func defaultAppearance() {
        backgroundColor = .clear
        usernameLabel.font = uiConfig.font.headlineBold

        usernameTagLabel.font = uiConfig.font.footnoteBold
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

        if let url = content?.imageURL {
            avatarView.imageView.setImage(from: url)
        } else {
            avatarView.imageView.image = UIImage(named: "pattern1", in: .streamChatUI)
        }

        suggestionTypeImageView.image = UIImage(named: "command_mention", in: .streamChatUI)
    }

    // MARK: Private

    private func setupLeftImageViewConstraints() {
        avatarView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        avatarView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        avatarView.bottomAnchor.pin(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        avatarView.widthAnchor.pin(equalToConstant: 40).isActive = true
        avatarView.heightAnchor.pin(equalTo: avatarView.widthAnchor).isActive = true
    }

    private func setupStack() {
        textStackView.axis = .vertical
        textStackView.distribution = .equalSpacing
        textStackView.alignment = .leading

        textStackView.addArrangedSubview(usernameLabel)
        textStackView.addArrangedSubview(usernameTagLabel)
        textStackView.centerYAnchor.pin(equalTo: centerYAnchor).isActive = true
        textStackView.leadingAnchor.pin(
            equalToSystemSpacingAfter: avatarView.trailingAnchor,
            multiplier: 1
        ).isActive = true
    }

    private func setupSuggestionTypeImageViewConstraints() {
        suggestionTypeImageView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        suggestionTypeImageView.centerYAnchor.pin(equalTo: centerYAnchor).isActive = true
    }
}

open class MessageComposerMentionCollectionViewCell<ExtraData: ExtraDataTypes>: UICollectionViewCell, UIConfigProvider {
    // MARK: Properties

    static var reuseId: String { String(describing: self) }

    public private(set) lazy var mentionView: MessageComposerMentionCellView<ExtraData> = {
        let view = uiConfig.messageComposer.suggestionsMentionCellView.init().withoutAutoresizingMaskConstraints
        contentView.embed(
            view,
            insets: .init(
                top: 0,
                leading: contentView.directionalLayoutMargins.leading,
                bottom: 0,
                trailing: contentView.directionalLayoutMargins.trailing
            )
        )
        return view
    }()
}
