//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays the command name, image and arguments.
public typealias ChatMessageComposerCommandCellView = _ChatMessageComposerCommandCellView<NoExtraData>

/// A view that displays the command name, image and arguments.
open class _ChatMessageComposerCommandCellView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    /// The command that the view will display.
    open var content: Command? {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    /// A view that displays the command image icon.
    open private(set) lazy var commandImageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
    
    /// A view that displays the name of the command.
    open private(set) lazy var commandNameLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
    
    /// A view that display the command name and the possible arguments.
    open private(set) lazy var commandNameSubtitleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
    
    /// A view container that holds the name and subtitle labels.
    open private(set) lazy var textStackView: UIStackView = UIStackView()
        .withoutAutoresizingMaskConstraints

    override public func defaultAppearance() {
        backgroundColor = .clear

        commandNameLabel.font = uiConfig.font.bodyBold
        commandNameLabel.textColor = uiConfig.colorPalette.text

        commandNameSubtitleLabel.font = uiConfig.font.body
        commandNameSubtitleLabel.textColor = uiConfig.colorPalette.subtitleText
    }

    override open func setUpLayout() {
        addSubview(commandImageView)
        setupLeftImageViewConstraints()

        addSubview(textStackView)
        setupStack()
    }

    override open func updateContent() {
        guard let command = content else { return }
        commandNameSubtitleLabel.text = "/\(command.name) \(command.args)"
        commandNameLabel.text = command.name.firstUppercased

        commandImageView.image = uiConfig.images.commandIcons[command.name.lowercased()]
            ?? uiConfig.images.messageComposerCommandFallback
    }

    private func setupLeftImageViewConstraints() {
        commandImageView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        commandImageView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        commandImageView.bottomAnchor.pin(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        commandImageView.widthAnchor.pin(equalTo: commandImageView.heightAnchor).isActive = true
        commandImageView.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor).isActive = true
        commandImageView.heightAnchor.pin(equalToConstant: 24).isActive = true
    }

    private func setupStack() {
        textStackView.axis = .horizontal
        textStackView.distribution = .equalSpacing
        textStackView.alignment = .leading
        textStackView.spacing = UIStackView.spacingUseSystem

        textStackView.addArrangedSubview(commandNameLabel)
        textStackView.addArrangedSubview(commandNameSubtitleLabel)
        textStackView.leadingAnchor.pin(
            equalToSystemSpacingAfter: commandImageView.trailingAnchor,
            multiplier: 1
        ).isActive = true
        textStackView.trailingAnchor.pin(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor).isActive = true
        textStackView.centerYAnchor.pin(equalTo: commandImageView.centerYAnchor).isActive = true
    }
}

/// A view cell that displays a command.
public typealias ChatMessageComposerCommandCollectionViewCell = _ChatMessageComposerCommandCollectionViewCell<NoExtraData>

/// A view cell that displays a command.
open class _ChatMessageComposerCommandCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell, UIConfigProvider {
    open class var reuseId: String { String(describing: self) }

    public private(set) lazy var commandView = uiConfig
        .messageComposer
        .suggestionsCommandCellView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        contentView.embed(commandView)
    }
}
