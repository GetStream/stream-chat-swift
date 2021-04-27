//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageComposerCheckmarkControl: _Control, AppearanceProvider {
    // MARK: - Properties
    
    public var checkmarkHeight: CGFloat = 16
    
    // MARK: - Subviews
    
    public private(set) lazy var container = ContainerStackView()
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
        label.font = appearance.fonts.subheadline
        label.textColor = appearance.colorPalette.subtitleText
        
        checkmark.layer.cornerRadius = 4
        checkmark.layer.borderWidth = 2
        checkmark.layer.masksToBounds = true
    }
    
    override open func setUpLayout() {
        embed(container)
        
        preservesSuperviewLayoutMargins = true
        
        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true

        container.addArrangedSubview(checkmark)

        checkmark.heightAnchor.pin(equalToConstant: checkmarkHeight).isActive = true
        checkmark.widthAnchor.pin(equalToConstant: checkmarkHeight).isActive = true
        
        container.addArrangedSubview(label)
    }
    
    override open func updateContent() {
        let isSelectedImage = appearance.images.messageComposerAlsoSendToChannelCheck
            .tinted(with: appearance.colorPalette.background)
        checkmark.image = isSelected ? isSelectedImage : nil
        checkmark.backgroundColor = isSelected ? tintColor : .clear
        checkmark.layer.borderColor = isSelected ? tintColor.cgColor : appearance.colorPalette.border2.cgColor
    }
    
    // MARK: - Actions
    
    @objc func toggleSelected() {
        isSelected.toggle()
    }
}
