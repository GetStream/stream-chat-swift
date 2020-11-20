//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelView<ExtraData: UIExtraDataTypes>: UIView, AppearanceSetting {
    // MARK: - Default Appearance
    
    public class func initialAppearanceSetup(_ view: ChatChannelView<ExtraData>) {
        if #available(iOS 13, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white // Should be add custom support for dark theme?
        }
    }
    
    // MARK: - Properties
        
    public var channel: _ChatChannel<ExtraData>? {
        didSet { updateContent() }
    }
    
    // MARK: - Subviews
    
    public private(set) lazy var container: ContainerStackView = {
        let stack = ContainerStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    public private(set) lazy var channelAvatarView: AvatarView = {
        let avatar = uiConfig(ExtraData.self).channelList.avatarView.init()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        return avatar
    }()
    
    public private(set) lazy var channelNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public private(set) lazy var separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Subviews Appearance

    @objc public dynamic var channelNameLabelTextColor: UIColor {
        get { channelNameLabel.textColor }
        set { channelNameLabel.textColor = newValue }
    }
    
    @objc public dynamic var channelAvatarViewBackgroundColor: UIColor? {
        get { channelAvatarView.backgroundColor }
        set { channelAvatarView.backgroundColor = newValue }
    }
    
    @objc public dynamic var separatorColor: UIColor? {
        get { separatorView.backgroundColor }
        set { separatorView.backgroundColor = newValue }
    }
    
    // MARK: - Init
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        embed(container)
        // TODO: This should be called before `setupAppearance` is called but it doesn't have to be called in `init`
        applyDefaultAppearance()
        
        setupAppearance()
        setupLayout()
        updateContent()
    }
    
    // MARK: - Public
    
    open func setupAppearance() {
        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true
        container.centerStackView.isHidden = false
        container.centerStackView.spacing = UIStackView.spacingUseSystem
        container.centerStackView.alignment = .center
        container.centerStackView.distribution = .fill
        
        channelNameLabel.numberOfLines = 0
        channelNameLabel.font = .preferredFont(forTextStyle: .body)
        channelNameLabel.adjustsFontForContentSizeCategory = true
    }
    
    open func setupLayout() {
        container.centerStackView.addArrangedSubview(channelAvatarView)
        container.centerStackView.addArrangedSubview(channelNameLabel)
        
        addSubview(separatorView)

        NSLayoutConstraint.activate([
            // Layout avatar.
            channelAvatarView.widthAnchor.constraint(equalToConstant: 40),
            
            // Layout separator.
            separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    open func updateContent() {
        guard superview != nil else { return }
        
        channelNameLabel.text = channel?.displayName
        
        if let imageURL = channel?.imageURL {
            channelAvatarView.imageView.setImage(from: imageURL)
        } else {
            channelAvatarView.imageView.image = nil
        }
    }
}
