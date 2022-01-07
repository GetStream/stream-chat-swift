//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view to check/uncheck an option.
open class CheckboxControl: _Control, AppearanceProvider {
    // MARK: - Properties
    
    public var checkmarkHeight: CGFloat = 16
    
    // MARK: - Subviews
    
    public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var checkbox = UIImageView()
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
        
        checkbox.layer.cornerRadius = 4
        checkbox.layer.borderWidth = 2
        checkbox.layer.masksToBounds = true
    }
    
    override open func setUpLayout() {
        embed(container)
        
        preservesSuperviewLayoutMargins = true
        
        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true

        container.addArrangedSubview(checkbox)

        checkbox.heightAnchor.pin(equalToConstant: checkmarkHeight).isActive = true
        checkbox.widthAnchor.pin(equalToConstant: checkmarkHeight).isActive = true
        
        container.addArrangedSubview(label)
    }
    
    override open func updateContent() {
        let isSelectedImage = appearance.images.whiteCheckmark
            .tinted(with: appearance.colorPalette.background)
        checkbox.image = isSelected ? isSelectedImage : nil
        checkbox.backgroundColor = isSelected ? tintColor : .clear
        checkbox.layer.borderColor = isSelected ? tintColor.cgColor : appearance.colorPalette.border2.cgColor
    }
    
    // MARK: - Actions
    
    @objc func toggleSelected() {
        isSelected.toggle()
    }
}
