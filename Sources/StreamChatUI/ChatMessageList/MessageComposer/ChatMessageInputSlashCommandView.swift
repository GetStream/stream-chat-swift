//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageInputSlashCommandView = _ChatMessageInputSlashCommandView<NoExtraData>

internal class _ChatMessageInputSlashCommandView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    // MARK: - Properties
    
    internal var commandName: String? {
        didSet {
            updateContentIfNeeded()
        }
    }

    // MARK: - Subviews
    
    internal private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    private lazy var commandLabel = UILabel()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var iconView = UIImageView()
        .withoutAutoresizingMaskConstraints
    
    // MARK: - Overrides
    
    override internal var intrinsicContentSize: CGSize {
        container.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
    
    override internal func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = bounds.height / 2
    }
    
    // MARK: - internal

    override internal func defaultAppearance() {
        layer.masksToBounds = true
        backgroundColor = uiConfig.colorPalette.highlightedAccentBackground

        commandLabel.textColor = uiConfig.colorPalette.staticColorText
        commandLabel.font = uiConfig.fonts.subheadlineBold

        commandLabel.adjustsFontForContentSizeCategory = true
        commandLabel.textAlignment = .center
        
        iconView.image = uiConfig.images.messageComposerCommand.tinted(with: uiConfig.colorPalette.staticColorText)
    }
    
    override internal func setUpLayout() {
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
    
    override internal func updateContent() {
        commandLabel.text = commandName
    }
}
