//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelDetailSelectionActionView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    // MARK: - Subviews
    
    public private(set) lazy var leadingIconView: UIImageView = {
        let imageView = UIImageView().withoutAutoresizingMaskConstraints
        imageView.contentMode = .center
        return imageView
    }()
    
    public private(set) lazy var titleLabel = UILabel().withoutAutoresizingMaskConstraints
   
    public private(set) lazy var trailingIconView: UIImageView = {
        let imageView = UIImageView().withoutAutoresizingMaskConstraints
        imageView.contentMode = .center
        return imageView
    }()

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
        leadingIconView.tintColor = uiConfig.colorPalette.channelDetailDefaultActionColor
        trailingIconView.tintColor = uiConfig.colorPalette.channelDetailDefaultActionColor
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        addSubview(leadingIconView)
        addSubview(titleLabel)
        addSubview(trailingIconView)
        
        NSLayoutConstraint.activate([
            leadingIconView.leadingAnchor.pin(equalToSystemSpacingAfter: layoutMarginsGuide.leadingAnchor, multiplier: 1.5),
            leadingIconView.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor),
            leadingIconView.widthAnchor.pin(equalToConstant: 20),
            titleLabel.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor),
            titleLabel.leadingAnchor.pin(equalToSystemSpacingAfter: leadingIconView.trailingAnchor, multiplier: 2),
            trailingIconView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor, constant: -8),
            trailingIconView.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor)
        ])
    }
}
