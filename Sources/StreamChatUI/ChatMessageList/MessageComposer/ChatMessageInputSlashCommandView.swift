//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageInputSlashCommandView = _ChatMessageInputSlashCommandView<NoExtraData>

open class _ChatMessageInputSlashCommandView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    // MARK: - Properties
    
    public var commandName: String? {
        didSet {
            updateContentIfNeeded()
        }
    }

    // MARK: - Subviews
    
    public private(set) lazy var container = DeprecatedContainerStackView()
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
        backgroundColor = uiConfig.colorPalette.highlightedAccentBackground

        commandLabel.textColor = uiConfig.colorPalette.staticColorText
        commandLabel.font = uiConfig.font.subheadlineBold

        commandLabel.adjustsFontForContentSizeCategory = true
        commandLabel.textAlignment = .center
        
        iconView.image = uiConfig.images.messageComposerCommand.tinted(with: uiConfig.colorPalette.staticColorText)
    }
    
    override open func setUpLayout() {
        embed(container)
        
        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true
        
        container.centerContainerStackView.spacing = UIStackView.spacingUseSystem
                
        container.leftStackView.isHidden = false
        container.leftStackView.addArrangedSubview(iconView)
        
        container.rightStackView.isHidden = false
        container.rightStackView.addArrangedSubview(commandLabel)
        
        iconView.contentMode = .scaleAspectFit
    }
    
    override open func updateContent() {
        commandLabel.text = commandName
    }
}
