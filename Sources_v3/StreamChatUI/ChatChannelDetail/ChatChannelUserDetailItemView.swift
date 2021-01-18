//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelUserDetailItemView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    // MARK: - Properties
    
    public var item: ChatChannelDetailItemSetup? {
        didSet {
            updateContent()
        }
    }
    
    // MARK: - Subviews
    
    public private(set) lazy var iconView: UIImageView = {
        let imageView = UIImageView().withoutAutoresizingMaskConstraints
        imageView.contentMode = .center
        imageView.tintColor = uiConfig.colorPalette.channelDetailIconColor
        return imageView
    }()
    
    public private(set) lazy var titleLabel = UILabel().withoutAutoresizingMaskConstraints
    
    public private(set) lazy var accessoryView = UIView().withoutAutoresizingMaskConstraints
    
    private lazy var switchView: UISwitch = {
        let switchView = UISwitch().withoutAutoresizingMaskConstraints
        return switchView
    }()
   
    private lazy var indicatorView: UIImageView = {
        let imageView = UIImageView().withoutAutoresizingMaskConstraints
        imageView.contentMode = .center
        imageView.tintColor = uiConfig.colorPalette.channelDetailIconColor
        imageView.image = uiConfig.channelDetail.icon.indicator
        return imageView
    }()

    // MARK: - Public

    override public func defaultAppearance() {
        super.defaultAppearance()
        backgroundColor = uiConfig.colorPalette.generalBackground
    }

    override open func setUpAppearance() {
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium) // TODO: Dominik's Typography PR
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(accessoryView)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.pin(equalToSystemSpacingAfter: layoutMarginsGuide.leadingAnchor, multiplier: 1.5),
            iconView.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor),
            iconView.widthAnchor.pin(equalToConstant: 20),
            titleLabel.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor),
            titleLabel.leadingAnchor.pin(equalToSystemSpacingAfter: iconView.trailingAnchor, multiplier: 2),
            accessoryView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor, constant: -8),
            accessoryView.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor)
        ])
    }
    
    override open func updateContent() {
        // TODO: Localization
        switch item {
        case .notification:
            titleLabel.text = "Notification"
            iconView.image = uiConfig.channelDetail.icon.notification
            accessoryView.embed(switchView)
        case .muteUser:
            titleLabel.text = "Mute User"
            iconView.image = uiConfig.channelDetail.icon.mute
            accessoryView.embed(switchView)
        case .addGroup:
            titleLabel.text = "Add a Group Name" // TODO: should be different cell type
            iconView.image = nil
        case .muteGroup:
            titleLabel.text = "Mute Group"
            iconView.image = uiConfig.channelDetail.icon.mute
            accessoryView.embed(switchView)
        case .leaveGroup:
            titleLabel.text = "Leave Group"
            iconView.image = uiConfig.channelDetail.icon.leaveGroup
        case .blockUser:
            titleLabel.text = "Block User"
            iconView.image = uiConfig.channelDetail.icon.block
            accessoryView.embed(switchView)
        case .photosAndVideos:
            titleLabel.text = "Photos & Video"
            iconView.image = uiConfig.channelDetail.icon.photosAndVideos
            accessoryView.embed(indicatorView)
        case .files:
            titleLabel.text = "Files"
            iconView.image = uiConfig.channelDetail.icon.files
            accessoryView.embed(indicatorView)
        case .sharedGroups:
            titleLabel.text = "Shared Groups"
            iconView.image = uiConfig.channelDetail.icon.groups
            accessoryView.embed(indicatorView)
        case .none:
            break
        }
    }
}
