//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class MessageComposerCommandCellView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    // MARK: Properties

    open var content: (title: String, subtitle: String, commandImage: UIImage?)? {
        didSet {
            updateContentIfNeeded()
        }
    }

    open private(set) lazy var commandImageView: UIImageView = UIImageView().withoutAutoresizingMaskConstraints
    open private(set) lazy var commandNameLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints
    open private(set) lazy var commandNameSubtitleLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints
    private lazy var textStackView: UIStackView = UIStackView().withoutAutoresizingMaskConstraints

    // MARK: - Appearance

    override open func defaultAppearance() {
        backgroundColor = uiConfig.colorPalette.generalBackground

        commandNameLabel.font = UIFont.preferredFont(forTextStyle: .footnote).bold

        commandNameSubtitleLabel.font = .preferredFont(forTextStyle: .caption1)
        commandNameSubtitleLabel.textColor = uiConfig.colorPalette.subtitleText

        commandNameLabel.textColor = uiConfig.colorPalette.text
    }

    override open func setUpLayout() {
        addSubview(commandImageView)
        setupLeftImageViewConstraints()

        addSubview(textStackView)
        setupStack()
    }

    override open func updateContent() {
        commandNameSubtitleLabel.text = content?.subtitle
        commandNameLabel.text = content?.title
        commandImageView.image = content?.commandImage
    }

    // MARK: Private

    private func setupLeftImageViewConstraints() {
        commandImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        commandImageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        commandImageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        commandImageView.widthAnchor.constraint(equalTo: commandImageView.heightAnchor).isActive = true
        commandImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
    }

    private func setupStack() {
        textStackView.axis = .horizontal
        textStackView.distribution = .equalSpacing
        textStackView.alignment = .leading
        textStackView.spacing = UIStackView.spacingUseSystem

        textStackView.addArrangedSubview(commandNameLabel)
        textStackView.addArrangedSubview(commandNameSubtitleLabel)
        textStackView.leadingAnchor.constraint(
            equalToSystemSpacingAfter: commandImageView.trailingAnchor,
            multiplier: 1
        ).isActive = true
        textStackView.centerYAnchor.constraint(equalTo: commandImageView.centerYAnchor).isActive = true
    }
}

open class MessageComposerCommandCollectionViewCell<ExtraData: ExtraDataTypes>: UICollectionViewCell {
    // MARK: Properties

    var uiConfig: UIConfig<ExtraData> = .default
    static var reuseId: String { String(describing: self) }

    public private(set) lazy var commandView: MessageComposerCommandCellView<ExtraData> = {
        let view = uiConfig.messageComposer.suggestionsCommandCellView.init().withoutAutoresizingMaskConstraints
        contentView.embed(view)
        return view
    }()
}
