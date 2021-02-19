//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageComposerCheckmarkControl = _ChatMessageComposerCheckmarkControl<NoExtraData>

internal class _ChatMessageComposerCheckmarkControl<ExtraData: ExtraDataTypes>: _Control, UIConfigProvider {
    // MARK: - Properties
    
    internal var checkmarkHeight: CGFloat = 16
    
    // MARK: - Subviews
    
    internal private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var checkmark = UIImageView()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var label = UILabel()
        .withoutAutoresizingMaskConstraints
        
    // MARK: - Overrides
    
    override internal var isSelected: Bool {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    override internal func setUp() {
        super.setUp()
        
        container.isUserInteractionEnabled = false
        
        addTarget(self, action: #selector(toggleSelected), for: .touchUpInside)
    }
    
    override internal func defaultAppearance() {
        label.font = uiConfig.fonts.subheadline
        label.textColor = uiConfig.colorPalette.subtitleText
        
        checkmark.layer.cornerRadius = 4
        checkmark.layer.borderWidth = 2
        checkmark.layer.masksToBounds = true
    }
    
    override internal func setUpLayout() {
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
    
    override internal func updateContent() {
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
