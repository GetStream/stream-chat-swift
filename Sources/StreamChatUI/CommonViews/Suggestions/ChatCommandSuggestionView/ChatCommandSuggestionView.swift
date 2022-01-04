//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays the command name, image and arguments.
open class ChatCommandSuggestionView: _View, AppearanceProvider {
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
        .withBidirectionalLanguagesSupport
    
    /// A view that display the command name and the possible arguments.
    open private(set) lazy var commandNameSubtitleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
    
    /// A view container that holds the name and subtitle labels.
    open private(set) lazy var textContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = .clear

        commandNameLabel.font = appearance.fonts.bodyBold
        commandNameLabel.textColor = appearance.colorPalette.text

        commandNameSubtitleLabel.font = appearance.fonts.body
        commandNameSubtitleLabel.textColor = appearance.colorPalette.subtitleText
    }

    override open func setUpLayout() {
        addSubview(commandImageView)
        setupLeftImageViewConstraints()

        addSubview(textContainer)
        setupStack()
        commandNameSubtitleLabel.setContentCompressionResistancePriority(.streamLow, for: .horizontal)
    }

    override open func updateContent() {
        guard let command = content else { return }
        commandNameSubtitleLabel.text = "/\(command.name) \(command.args)"
        commandNameLabel.text = command.name.firstUppercased

        commandImageView.image = appearance.images.commandIcons[command.name.lowercased()]
            ?? appearance.images.commandFallback
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
        textContainer.axis = .horizontal
        textContainer.alignment = .leading

        textContainer.addArrangedSubview(commandNameLabel)
        textContainer.addArrangedSubview(commandNameSubtitleLabel)
        textContainer.leadingAnchor.pin(
            equalToSystemSpacingAfter: commandImageView.trailingAnchor,
            multiplier: 1
        ).isActive = true
        textContainer.trailingAnchor.pin(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor).isActive = true
        textContainer.centerYAnchor.pin(equalTo: commandImageView.centerYAnchor).isActive = true
    }
}
