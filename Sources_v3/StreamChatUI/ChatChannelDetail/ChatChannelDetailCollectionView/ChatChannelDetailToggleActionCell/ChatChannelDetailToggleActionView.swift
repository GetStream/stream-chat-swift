//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelDetailToggleActionView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    // MARK: - Subviews
    
    public private(set) lazy var iconView: UIImageView = {
        let imageView = UIImageView().withoutAutoresizingMaskConstraints
        imageView.contentMode = .center
        return imageView
    }()
    
    public private(set) lazy var titleLabel = UILabel().withoutAutoresizingMaskConstraints
    
    private lazy var switchView: UISwitch = {
        let switchView = UISwitch().withoutAutoresizingMaskConstraints
        return switchView
    }()
    
    public var onChange: ((Bool) -> Void)?

    // MARK: - Public
    
    override open func setUp() {
        super.setUp()
        switchView.addTarget(self, action: #selector(didChangeSwitchValue(_:)), for: .valueChanged)
    }

    override open func defaultAppearance() {
        super.defaultAppearance()
        backgroundColor = uiConfig.colorPalette.generalBackground
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium) // TODO: Dominik's Typography PR
        titleLabel.textColor = uiConfig.colorPalette.channelDetailDefaultTextColor
        iconView.tintColor = uiConfig.colorPalette.channelDetailDefaultActionColor
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(switchView)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.pin(equalToSystemSpacingAfter: layoutMarginsGuide.leadingAnchor, multiplier: 1.5),
            iconView.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor),
            iconView.widthAnchor.pin(equalToConstant: 20),
            titleLabel.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor),
            titleLabel.leadingAnchor.pin(equalToSystemSpacingAfter: iconView.trailingAnchor, multiplier: 2),
            switchView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor, constant: -8),
            switchView.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc func didChangeSwitchValue(_ sender: UISwitch) {
        onChange?(sender.isOn)
    }
}
