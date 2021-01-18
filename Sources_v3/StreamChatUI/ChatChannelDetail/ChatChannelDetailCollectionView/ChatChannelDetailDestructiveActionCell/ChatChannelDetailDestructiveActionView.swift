//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelDetailDestructiveActionView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    // MARK: - Subviews
    
    public private(set) lazy var iconView: UIImageView = {
        let imageView = UIImageView().withoutAutoresizingMaskConstraints
        imageView.contentMode = .center
        return imageView
    }()
    
    public private(set) lazy var titleLabel = UILabel().withoutAutoresizingMaskConstraints

    // MARK: - Public

    override public func defaultAppearance() {
        super.defaultAppearance()
        backgroundColor = uiConfig.colorPalette.generalBackground
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium) // TODO: Dominik's Typography PR
        titleLabel.textColor = uiConfig.colorPalette.channelDetailDestructiveActionColor
        iconView.tintColor = uiConfig.colorPalette.channelDetailDestructiveActionColor
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        addSubview(iconView)
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.pin(equalToSystemSpacingAfter: layoutMarginsGuide.leadingAnchor, multiplier: 1.5),
            iconView.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor),
            iconView.widthAnchor.pin(equalToConstant: 20),
            titleLabel.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor),
            titleLabel.leadingAnchor.pin(equalToSystemSpacingAfter: iconView.trailingAnchor, multiplier: 2)
        ])
    }
}
