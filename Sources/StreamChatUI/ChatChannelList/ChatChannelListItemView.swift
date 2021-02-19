//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A  `ChatChannelSwipeableListItemView` subclass view that shows channel information.
internal typealias ChatChannelListItemView = _ChatChannelListItemView<NoExtraData>

/// A  `ChatChannelSwipeableListItemView` subclass view that shows channel information.
internal class _ChatChannelListItemView<ExtraData: ExtraDataTypes>: _ChatChannelSwipeableListItemView<ExtraData> {
    /// The data this view component shows.
    internal var content: (channel: _ChatChannel<ExtraData>?, currentUserId: UserId?) {
        didSet { updateContentIfNeeded() }
    }
        
    private lazy var uiConfigSubviews: _UIConfig.ChannelListItemSubviews = uiConfig.channelList.channelListItemSubviews
    
    /// The `ContainerStackView` instance used to arrange view,
    internal private(set) lazy var container: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints
    
    /// The `UILabel` instance showing the channel name.
    internal private(set) lazy var titleLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints
    
    /// The `UILabel` instance showing the last message or typing members if any.
    internal private(set) lazy var subtitleLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints
    
    /// The `UILabel` instance showing the time of the last sent message.
    internal private(set) lazy var timestampLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints
    
    /// The view used to show channels avatar.
    internal private(set) lazy var avatarView: _ChatChannelAvatarView<ExtraData> = uiConfigSubviews
        .avatarView
        .init()
        .withoutAutoresizingMaskConstraints
    
    /// The view showing number of unread messages in channel if any.
    internal private(set) lazy var unreadCountView: _ChatChannelUnreadCountView<ExtraData> = uiConfigSubviews
        .unreadCountView.init()
        .withoutAutoresizingMaskConstraints

    /// The view showing indicator for read status of the last message in channel.
    internal private(set) lazy var readStatusView: _ChatChannelReadStatusCheckmarkView<ExtraData> = uiConfigSubviews
        .readStatusView.init()
        .withoutAutoresizingMaskConstraints

    override internal func defaultAppearance() {
        super.defaultAppearance()

        backgroundColor = uiConfig.colorPalette.background

        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = uiConfig.fonts.bodyBold

        subtitleLabel.textColor = uiConfig.colorPalette.subtitleText
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.font = uiConfig.fonts.subheadline
        
        timestampLabel.textColor = uiConfig.colorPalette.subtitleText
        timestampLabel.adjustsFontForContentSizeCategory = true
        timestampLabel.font = uiConfig.fonts.subheadline
    }

    override internal func setUpLayout() {
        super.setUpLayout()

        cellContentView.embed(container, insets: directionalLayoutMargins)
                
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
        stackView.pin(anchors: [.leading, .centerY], to: containerCenterView)
        stackView.trailingAnchor.pin(equalTo: containerCenterView.trailingAnchor).with(priority: .streamAlmostRequire)
            .isActive = true
        stackView.spacing = 2
        
        let topCenterStackView = UIStackView()
        topCenterStackView.alignment = .top
        topCenterStackView.spacing = UIStackView.spacingUseSystem
        topCenterStackView.addArrangedSubview(titleLabel)
        topCenterStackView.addArrangedSubview(unreadCountView)
        
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
    
    override internal func updateContent() {
        if let channel = content.channel {
            let namer = uiConfig.channelList.channelNamer.init()
            titleLabel.text = namer.name(for: channel, as: content.currentUserId)
        } else {
            titleLabel.text = L10n.Channel.Name.missing
        }
                
        subtitleLabel.text = typingMemberOrLastMessageString

        avatarView.content = .channelAndUserId(channel: content.channel, currentUserId: content.currentUserId)

        unreadCountView.content = content.channel?.unreadCount ?? .noUnread
        unreadCountView.invalidateIntrinsicContentSize()
                
        timestampLabel.text = content.channel?.lastMessageAt?.getFormattedDate(format: "hh:mm a")
        
        // TODO: ReadStatusView
        // Missing LLC API
        readStatusView.isHidden = true
    }
}

extension _ChatChannelListItemView {
    var typingMemberString: String? {
        guard let members = content.channel?.currentlyTypingMembers, !members.isEmpty else { return nil }
        let names = members.compactMap(\.name).sorted()
        return names.joined(separator: ", ") + " \(names.count == 1 ? "is" : "are") typing..."
    }
    
    var typingMemberOrLastMessageString: String? {
        guard let channel = content.channel else { return nil }
        if let typingMembersInfo = typingMemberString {
            return typingMembersInfo
        } else if let latestMessage = channel.latestMessages.first {
            return "\(latestMessage.author.name ?? latestMessage.author.id): \(latestMessage.text)"
        } else {
            return "No messages"
        }
    }
}
