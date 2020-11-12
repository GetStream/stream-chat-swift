//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelView<ExtraData: UIExtraDataTypes>: UIView {
    
    // MARK: - Properties
    
    public let uiConfig: UIConfig<ExtraData>
    
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
        let avatar = uiConfig.channelList.avatarView.init()
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
    
    public required init(
        channel: _ChatChannel<ExtraData>? = nil,
        uiConfig: UIConfig<ExtraData> = .default
    ) {
        self.channel = channel
        self.uiConfig = uiConfig
        
        super.init(frame: .zero)
        
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        self.uiConfig = .default
        self.channel = nil
        
        super.init(coder: coder)
        
        commonInit()
    }
    
    public func commonInit() {
        setupAppearance()
        setupLayout()
        updateContent()
    }
    
    // MARK: - Public
    
    open func setupAppearance() {
        channelNameLabel.numberOfLines = 1
        channelNameLabel.font = UIFontMetrics(forTextStyle: .subheadline)
            .scaledFont(for: .boldSystemFont(ofSize: UIFont.systemFontSize))
    }
    
    open func setupLayout() {
        embedUsingSystemSpacing(container)
        
        container.centerStackView.isHidden = false
        container.centerStackView.spacing = 8
        container.centerStackView.alignment = .center
        container.centerStackView.distribution = .fill
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
        channelNameLabel.text = channel?.displayName
        
        if let imageURL = channel?.imageURL {
            channelAvatarView.imageView.setImage(from: imageURL)
        } else {
            channelAvatarView.imageView.image = nil
        }
    }
}
