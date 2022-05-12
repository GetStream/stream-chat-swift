//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// A button for showing a cooldown when Slow Mode is active.
open class CooldownView: _View, AppearanceProvider {
    public private(set) lazy var cooldownLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "cooldownLabel")
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        embed(cooldownLabel, insets: .init(top: 6, leading: 10, bottom: 6, trailing: 10))
        cooldownLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()

        clipsToBounds = true
        backgroundColor = appearance.colorPalette.alternativeInactiveTint
        cooldownLabel.font = appearance.fonts.bodyBold
        cooldownLabel.textColor = appearance.colorPalette.textInverted
        cooldownLabel.adjustsFontForContentSizeCategory = true
    }
}
