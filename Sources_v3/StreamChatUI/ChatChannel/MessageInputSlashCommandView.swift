//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

open class MessageInputSlashCommandView: UIView {
    // MARK: - Properties
        
    override open var intrinsicContentSize: CGSize {
        container.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    // MARK: - Subviews
    
    private lazy var container = ContainerStackView().withoutAutoresizingMaskConstraints
    
    private lazy var commandLabel = UILabel().withoutAutoresizingMaskConstraints
    
    private lazy var iconView = UIImageView().withoutAutoresizingMaskConstraints
    
    // MARK: - Init
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        embed(container)
        
        setupLayout()
        setupAppearance()
        updateContent()
    }
    
    // MARK: - Layout
    
    override open func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        
        commandLabel.invalidateIntrinsicContentSize()
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        invalidateIntrinsicContentSize()
        
        layer.cornerRadius = intrinsicContentSize.height / 2
    }
    
    // MARK: - Public
    
    open func setupAppearance() {
        layer.masksToBounds = true
        backgroundColor = .systemPurple
        commandLabel.textColor = .white
        commandLabel.font = UIFont.preferredFont(forTextStyle: .caption1).bold
        commandLabel.adjustsFontForContentSizeCategory = true
        commandLabel.textAlignment = .center
        
        if #available(iOS 13.0, *) {
            iconView.image = UIImage(systemName: "bolt.fill")
            iconView.tintColor = .white
        }
    }
    
    open func setupLayout() {
        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true
        
        container.spacing = UIStackView.spacingUseSystem
                
        container.leftStackView.isHidden = false
        container.leftStackView.addArrangedSubview(iconView)
        
        container.rightStackView.isHidden = false
        container.rightStackView.addArrangedSubview(commandLabel)
        
        iconView.contentMode = .scaleAspectFit
        iconView.heightAnchor.constraint(equalToConstant: commandLabel.font.pointSize).isActive = true
    }
    
    open func updateContent() {
        commandLabel.text = "GIPHY"
    }
}
