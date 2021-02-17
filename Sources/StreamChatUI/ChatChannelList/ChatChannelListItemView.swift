//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatChannelListItemView = _ChatChannelListItemView<NoExtraData>

open class _ChatChannelListItemView<ExtraData: ExtraDataTypes>: _ChatChannelSwipeableListItemView<ExtraData> {
    // MARK: - Properties

    open var normalBackgroundColor: UIColor?
    open var highlightedBackgroundColor: UIColor?

    public var channelAndUserId: (channel: _ChatChannel<ExtraData>?, currentUserId: UserId?) {
        didSet {
            updateContent()
        }
    }
    
    // MARK: - Subviews
    
    private lazy var uiConfigSubviews = uiConfig.channelList.channelListItemSubviews
    
    public private(set) lazy var container = ContainerStackView().withoutAutoresizingMaskConstraints
    
    public private(set) lazy var avatarView = uiConfigSubviews
        .avatarView
        .init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var titleLabel = UILabel().withoutAutoresizingMaskConstraints
    
    public private(set) lazy var subtitleLabel = UILabel().withoutAutoresizingMaskConstraints
    
    public private(set) lazy var unreadCountView: _ChatChannelUnreadCountView<ExtraData> = {
        uiConfigSubviews.unreadCountView.init().withoutAutoresizingMaskConstraints
    }()
    
    public private(set) lazy var readStatusView: _ChatChannelReadStatusCheckmarkView<ExtraData> = {
        uiConfigSubviews.readStatusView.init().withoutAutoresizingMaskConstraints
    }()
    
    public private(set) lazy var timestampLabel = UILabel().withoutAutoresizingMaskConstraints

    // MARK: - Public

    override public func defaultAppearance() {
        super.defaultAppearance()

        backgroundColor = uiConfig.colorPalette.background
        normalBackgroundColor = uiConfig.colorPalette.background
        highlightedBackgroundColor = uiConfig.colorPalette.highlightedBackground

        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = uiConfig.font.bodyBold

        subtitleLabel.textColor = uiConfig.colorPalette.subtitleText
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.font = uiConfig.font.subheadline
        
        timestampLabel.textColor = uiConfig.colorPalette.subtitleText
        timestampLabel.adjustsFontForContentSizeCategory = true
        timestampLabel.font = uiConfig.font.subheadline
    }

    override open func setUpLayout() {
        super.setUpLayout()

        cellContentView.embed(container)

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
        
        avatarView.heightAnchor.pin(equalToConstant: 48).isActive = true
        avatarView.widthAnchor.pin(equalTo: avatarView.heightAnchor).isActive = true
        container.leftStackView.addArrangedSubview(avatarView)
        
        // UIStackView embedded in UIView with flexible top and bottom constraints to make
        // containing UIStackView centred and preserving content size.
        let containerCenterView = UIView()
        let stackView = UIStackView()
        stackView.axis = .vertical
        
        containerCenterView.addSubview(stackView)
        stackView.topAnchor.pin(greaterThanOrEqualTo: containerCenterView.layoutMarginsGuide.topAnchor).isActive = true
        stackView.bottomAnchor.pin(lessThanOrEqualTo: containerCenterView.layoutMarginsGuide.bottomAnchor).isActive = true
        stackView.pin(anchors: [.leading, .trailing, .centerY], to: containerCenterView)
        stackView.spacing = 2
        
        // Top part of centerStackView.
        let topCenterStackView = UIStackView()
        topCenterStackView.alignment = .top
        topCenterStackView.spacing = UIStackView.spacingUseSystem
        topCenterStackView.addArrangedSubview(titleLabel)
        topCenterStackView.addArrangedSubview(unreadCountView)
        
        // Bottom part of centerStackView.
        let bottomCenterStackView = UIStackView()
        bottomCenterStackView.spacing = UIStackView.spacingUseSystem
        
        subtitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        timestampLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        bottomCenterStackView.addArrangedSubview(subtitleLabel)
        bottomCenterStackView.setCustomSpacing(UIStackView.spacingUseSystem, after: subtitleLabel)
        bottomCenterStackView.addArrangedSubview(readStatusView)
        bottomCenterStackView.addArrangedSubview(timestampLabel)
        
        stackView.addArrangedSubview(topCenterStackView)
        stackView.addArrangedSubview(bottomCenterStackView)
        
        container.centerStackView.isHidden = false
        container.centerStackView.addArrangedSubview(containerCenterView)
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
        
        avatarView.content = .channelAndUserId(channel: channelAndUserId.channel, currentUserId: channelAndUserId.currentUserId)
        
        // UnreadCount
        
        // Mock test code
        unreadCountView.unreadCount = channelAndUserId.channel?.unreadCount ?? .noUnread
        unreadCountView.invalidateIntrinsicContentSize()
        
        // Timestamp
        
        timestampLabel.text = channelAndUserId.channel?.lastMessageAt?.getFormattedDate(format: "hh:mm a")
        
        // TODO: ReadStatusView
        // Missing LLC API
        readStatusView.isHidden = true
    }
    
    open func resetContent() {
        titleLabel.text = ""
        subtitleLabel.text = ""
        avatarView.content = .channelAndUserId(channel: nil, currentUserId: nil)
        unreadCountView.unreadCount = .noUnread
        timestampLabel.text = ""
        readStatusView.status = .empty
    }
}

extension _ChatChannelListItemView {
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
