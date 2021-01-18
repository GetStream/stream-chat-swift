//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelDetailDisplayActionView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    // MARK: - Subviews
    
    public private(set) lazy var titleLabel = UILabel().withoutAutoresizingMaskConstraints
    
    public private(set) lazy var valueLabel = UILabel().withoutAutoresizingMaskConstraints

    // MARK: - Public

    override public func defaultAppearance() {
        super.defaultAppearance()
        backgroundColor = uiConfig.colorPalette.generalBackground
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium) // TODO: Dominik's Typography PR
        titleLabel.textColor = uiConfig.colorPalette.channelDetailDefaultTextColor
        valueLabel.textColor = uiConfig.colorPalette.channelDetailDefaultActionColor
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        addSubview(titleLabel)
        addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.pin(equalToSystemSpacingAfter: layoutMarginsGuide.leadingAnchor, multiplier: 1.5),
            titleLabel.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor),
            valueLabel.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor, constant: -8),
            valueLabel.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor)
        ])
    }
}
