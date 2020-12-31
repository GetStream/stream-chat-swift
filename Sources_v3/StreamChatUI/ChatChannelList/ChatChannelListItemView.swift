//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelListItemView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    override public func defaultAppearance() {
        backgroundColor = uiConfig.colorPalette.generalBackground
    }

    // MARK: - Properties
    
    public var uiConfig: UIConfig<ExtraData>

    public var channelAndUserId: (channel: _ChatChannel<ExtraData>?, currentUserId: UserId?) {
        didSet {
            updateContent()
        }
    }
    
    // MARK: - Subviews
    
    private lazy var uiConfigSubviews = uiConfig.channelList.channelListItemSubviews
    
    public private(set) lazy var container = ContainerStackView().withoutAutoresizingMaskConstraints
    
    public private(set) lazy var avatarView: ChatChannelAvatarView<ExtraData> = {
        uiConfigSubviews.avatarView.init().withoutAutoresizingMaskConstraints
    }()
    
    public private(set) lazy var titleLabel = UILabel().withoutAutoresizingMaskConstraints
    
    public private(set) lazy var subtitleLabel = UILabel().withoutAutoresizingMaskConstraints
    
    public private(set) lazy var unreadCountView: ChatUnreadCountView = {
        uiConfigSubviews.unreadCountView.init().withoutAutoresizingMaskConstraints
    }()
    
    public private(set) lazy var readStatusView: ChatReadStatusCheckmarkView = {
        uiConfigSubviews.readStatusView.init().withoutAutoresizingMaskConstraints
    }()
    
    public private(set) lazy var timestampLabel = UILabel().withoutAutoresizingMaskConstraints
    
    // MARK: - Init
    
    public required init(
        channel: _ChatChannel<ExtraData>? = nil,
        userId: UserId? = nil,
        uiConfig: UIConfig<ExtraData> = .default
    ) {
        channelAndUserId = (channel, userId)
        self.uiConfig = uiConfig
        
        super.init(frame: .zero)
        
        self.uiConfig = uiConfig
    }
    
    public required init?(coder: NSCoder) {
        uiConfig = .default
        channelAndUserId = (nil, nil)
        
        super.init(coder: coder)
    }
    
    // MARK: - Public
    
    override open func setUpAppearance() {
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        
        subtitleLabel.textColor = uiConfig.colorPalette.subtitleText
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        
        timestampLabel.textColor = uiConfig.colorPalette.subtitleText
        timestampLabel.adjustsFontForContentSizeCategory = true
        timestampLabel.font = .preferredFont(forTextStyle: .subheadline)
    }
    
    override open func setUpLayout() {
        embed(container)
        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true
                
        container.leftStackView.isHidden = false
        container.leftStackView.alignment = .center
        container.leftStackView.isLayoutMarginsRelativeArrangement = true
        container.leftStackView.directionalLayoutMargins = .init(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: avatarView.directionalLayoutMargins.trailing
        )
        
        container.leftStackView.addArrangedSubview(avatarView)
        
        // UIStackView embedded in UIView with flexible top and bottom constraints to make
        // containing UIStackView centred and preserving content size.
        let containerCenterView = UIView()
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = UIStackView.spacingUseSystem
        
        containerCenterView.addSubview(stackView)
        stackView.topAnchor.constraint(greaterThanOrEqualTo: containerCenterView.topAnchor, constant: 0).isActive = true
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: containerCenterView.bottomAnchor, constant: 0).isActive = true
        stackView.pin(anchors: [.leading, .trailing, .centerY], to: containerCenterView)
        
        // Top part of centerStackView.
        let topCenterStackView = UIStackView()
        topCenterStackView.alignment = .top
        topCenterStackView.addArrangedSubview(titleLabel)
        topCenterStackView.addArrangedSubview(unreadCountView)
        
        // Bottom part of centerStackView.
        let bottomCenterStackView = UIStackView()
        bottomCenterStackView.spacing = UIStackView.spacingUseSystem
        
        subtitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        timestampLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        bottomCenterStackView.addArrangedSubview(subtitleLabel)
        bottomCenterStackView.addArrangedSubview(readStatusView)
        bottomCenterStackView.addArrangedSubview(timestampLabel)
        
        stackView.addArrangedSubview(topCenterStackView)
        stackView.addArrangedSubview(bottomCenterStackView)
        
        container.centerStackView.isHidden = false
        container.centerStackView.addArrangedSubview(containerCenterView)
    
        avatarView.widthAnchor.constraint(equalToConstant: avatarView.intrinsicContentSize.width).isActive = true
    }
    
    override open func updateContent() {
        // Title
        if let channel = channelAndUserId.channel {
            let namer = uiConfig.channelList.channelNamer.init()
            titleLabel.text = namer.name(for: channel, as: channelAndUserId.currentUserId)
        } else {
            titleLabel.text = L10n.Channel.Name.missing
        }
        
        // Subtitle
        
        subtitleLabel.text = typingMemberOrLastMessageString
        
        // Avatar
        
        avatarView.channelAndUserId = channelAndUserId
        
        // UnreadCount
        
        // Mock test code
        unreadCountView.unreadCount = channelAndUserId.channel?.unreadCount ?? .noUnread
        unreadCountView.invalidateIntrinsicContentSize()
        
        // Timestamp
        
        timestampLabel.text = channelAndUserId.channel?.lastMessageAt?.getFormattedDate(format: "hh:mm a")
        
        // TODO: ReadStatusView
        // Missing LLC API
    }
    
    open func resetContent() {
        titleLabel.text = ""
        subtitleLabel.text = ""
        avatarView.channelAndUserId = (nil, nil)
        unreadCountView.unreadCount = .noUnread
        timestampLabel.text = ""
        readStatusView.status = .empty
    }
}

extension ChatChannelListItemView {
    var typingMemberString: String? {
        guard let members = channelAndUserId.channel?.currentlyTypingMembers, !members.isEmpty else { return nil }
        let names = members.compactMap(\.name).sorted()
        return names.joined(separator: ", ") + " \(names.count == 1 ? "is" : "are") typing..."
    }
    
    var typingMemberOrLastMessageString: String? {
        guard let channel = channelAndUserId.channel else { return nil }
        if let typingMembersInfo = typingMemberString {
            return typingMembersInfo
        } else if let latestMessage = channel.latestMessages.first {
            return "\(latestMessage.author.name ?? latestMessage.author.id): \(latestMessage.text)"
        } else {
            return "No messages"
        }
    }
}
