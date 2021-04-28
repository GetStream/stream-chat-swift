//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that display the command name and icon.
public typealias ChatCommandLabel = _ChatCommandLabel<NoExtraData>

/// A view that display the command name and icon.
open class _ChatCommandLabel<ExtraData: ExtraDataTypes>: _View, AppearanceProvider {
    /// The command that the label displays.
    public var content: Command? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The container stack view that layouts the label and the icon view.
    public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// An `UILabel` that displays the command name.
    public private(set) lazy var commandLabel = UILabel()
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints

    /// An `UIImageView` that displays the icon of the command.
    public private(set) lazy var iconView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
    
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

        commandLabel.textColor = appearance.colorPalette.staticColorText
        commandLabel.font = appearance.fonts.subheadlineBold

        commandLabel.adjustsFontForContentSizeCategory = true
        commandLabel.textAlignment = .center
        
        iconView.image = appearance.images.messageComposerCommand
            .tinted(with: appearance.colorPalette.staticColorText)
    }
    
    override open func setUpLayout() {
        super.setUpLayout()

        embed(container)
        container.isLayoutMarginsRelativeArrangement = true
        container.layoutMargins.top = 4
        container.layoutMargins.bottom = 4

        container.addArrangedSubview(iconView)
        container.addArrangedSubview(commandLabel)
        iconView.isHidden = false
        commandLabel.isHidden = false
        
        iconView.contentMode = .scaleAspectFit
    }
    
    override open func updateContent() {
        super.updateContent()
        
        commandLabel.text = content?.name.uppercased()
    }
}
