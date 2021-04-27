//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageInputSlashCommandView: _View, AppearanceProvider {
    // MARK: - Properties
    
    public var commandName: String? {
        didSet {
            updateContentIfNeeded()
        }
    }

    // MARK: - Subviews
    
    public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    private lazy var commandLabel = UILabel()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var iconView = UIImageView()
        .withoutAutoresizingMaskConstraints
    
    // MARK: - Overrides
    
    override open var intrinsicContentSize: CGSize {
        container.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.height / 2
    }
    
    // MARK: - Public

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
        embed(container)
        
        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true

        container.addArrangedSubview(iconView)
        iconView.isHidden = false

        container.addArrangedSubview(commandLabel)
        commandLabel.isHidden = false
        
        iconView.contentMode = .scaleAspectFit
    }
    
    override open func updateContent() {
        commandLabel.text = commandName
    }
}
