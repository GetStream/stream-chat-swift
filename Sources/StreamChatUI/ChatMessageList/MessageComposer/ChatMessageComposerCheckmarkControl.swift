//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageComposerCheckmarkControl = _ChatMessageComposerCheckmarkControl<NoExtraData>

open class _ChatMessageComposerCheckmarkControl<ExtraData: ExtraDataTypes>: _Control, UIConfigProvider {
    // MARK: - Properties
    
    public var checkmarkHeight: CGFloat = 16
    
    // MARK: - Subviews
    
    public private(set) lazy var container = DeprecatedContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var checkmark = UIImageView()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var label = UILabel()
        .withoutAutoresizingMaskConstraints
        
    // MARK: - Overrides
    
    override open var isSelected: Bool {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    override open func setUp() {
        super.setUp()
        
        container.isUserInteractionEnabled = false
        
        addTarget(self, action: #selector(toggleSelected), for: .touchUpInside)
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        label.font = uiConfig.font.subheadline
        label.textColor = uiConfig.colorPalette.subtitleText
        
        checkmark.layer.cornerRadius = 4
        checkmark.layer.borderWidth = 2
        checkmark.layer.masksToBounds = true
    }
    
    override open func setUpLayout() {
        embed(container)
        
        preservesSuperviewLayoutMargins = true
        
        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true
        
        container.centerContainerStackView.spacing = UIStackView.spacingUseSystem
        
        container.leftStackView.isHidden = false
        container.leftStackView.alignment = .center
        container.leftStackView.addArrangedSubview(checkmark)

        checkmark.heightAnchor.pin(equalToConstant: checkmarkHeight).isActive = true
        checkmark.widthAnchor.pin(equalToConstant: checkmarkHeight).isActive = true
        
        container.centerStackView.isHidden = false
        container.centerStackView.alignment = .center
        container.centerStackView.addArrangedSubview(label)
    }
    
    override open func updateContent() {
        let isSelectedImage = uiConfig.images.messageComposerAlsoSendToChannelCheck.tinted(with: uiConfig.colorPalette.background)
        checkmark.image = isSelected ? isSelectedImage : nil
        checkmark.backgroundColor = isSelected ? tintColor : .clear
        checkmark.layer.borderColor = isSelected ? tintColor.cgColor : uiConfig.colorPalette.border2.cgColor
    }
    
    // MARK: - Actions
    
    @objc func toggleSelected() {
        isSelected.toggle()
    }
}
