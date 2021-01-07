//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class MessageInputSlashCommandView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
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
    
    override public func defaultAppearance() {
        layer.masksToBounds = true
        backgroundColor = uiConfig.colorPalette.slashCommandViewBackground
        
        commandLabel.textColor = uiConfig.colorPalette.slashCommandViewText
        commandLabel.font = UIFont.preferredFont(forTextStyle: .caption1).bold
        commandLabel.adjustsFontForContentSizeCategory = true
        commandLabel.textAlignment = .center
        
        iconView.image = UIImage(named: "bolt", in: .streamChatUI)?.tinted(with: uiConfig.colorPalette.slashCommandViewText)
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
        iconView.heightAnchor.pin(equalToConstant: commandLabel.font.pointSize).isActive = true
    }
    
    override open func updateContent() {
        commandLabel.text = commandName
    }
}
