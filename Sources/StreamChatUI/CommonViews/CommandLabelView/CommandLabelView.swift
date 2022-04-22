//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that display the command name and icon.
open class CommandLabelView: _View, AppearanceProvider, SwiftUIRepresentable {
    /// The command that the label displays.
    public var content: Command? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The container stack view that layouts the label and the icon view.
    public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "container")

    /// An `UILabel` that displays the command name.
    public private(set) lazy var nameLabel = UILabel()
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "nameLabel")

    /// An `UIImageView` that displays the icon of the command.
    public private(set) lazy var iconView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "iconView")
    
    override open var intrinsicContentSize: CGSize {
        container.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.height / 2
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        layer.masksToBounds = true
        backgroundColor = appearance.colorPalette.highlightedAccentBackground

        nameLabel.textColor = appearance.colorPalette.staticColorText
        nameLabel.font = appearance.fonts.subheadlineBold

        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textAlignment = .center
        
        iconView.image = appearance.images.commands
            .tinted(with: appearance.colorPalette.staticColorText)
    }
    
    override open func setUpLayout() {
        super.setUpLayout()

        embed(container)
        container.isLayoutMarginsRelativeArrangement = true
        container.layoutMargins.top = 4
        container.layoutMargins.bottom = 4

        container.addArrangedSubview(iconView)
        container.addArrangedSubview(nameLabel)
        iconView.isHidden = false
        nameLabel.isHidden = false
        
        iconView.contentMode = .scaleAspectFit
    }
    
    override open func updateContent() {
        super.updateContent()
        
        nameLabel.text = content?.name.uppercased()
    }
}
