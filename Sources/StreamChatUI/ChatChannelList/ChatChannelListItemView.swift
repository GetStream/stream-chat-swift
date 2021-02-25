//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A `ChatChannelSwipeableListItemView` subclass view that shows channel information.
public typealias ChatChannelListItemView = _ChatChannelListItemView<NoExtraData>

/// A `ChatChannelSwipeableListItemView` subclass view that shows channel information.
open class _ChatChannelListItemView<ExtraData: ExtraDataTypes>: _ChatChannelSwipeableListItemView<ExtraData> {
    
    /// The data this view component shows.
    public var content: (channel: _ChatChannel<ExtraData>?, currentUserId: UserId?) {
        didSet { updateContentIfNeeded() }
    }
        
    private lazy var uiConfigSubviews: _UIConfig.ChannelListItemSubviews = uiConfig.channelList.channelListItemSubviews
    
    /// The `UILabel` instance showing the channel name.
    open private(set) lazy var titleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
    
    /// The `UILabel` instance showing the last message or typing members if any.
    open private(set) lazy var subtitleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
    
    /// The `UILabel` instance showing the time of the last sent message.
    open private(set) lazy var timestampLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
    
    /// The view used to show channels avatar.
    open private(set) lazy var avatarView: _ChatChannelAvatarView<ExtraData> = uiConfigSubviews
        .avatarView
        .init()
        .withoutAutoresizingMaskConstraints
    
    /// The view showing number of unread messages in channel if any.
    open private(set) lazy var unreadCountView: _ChatChannelUnreadCountView<ExtraData> = uiConfigSubviews
        .unreadCountView.init()
        .withoutAutoresizingMaskConstraints

    /*
        TODO: ReadStatusView, Missing LLC API
    /// The view showing indicator for read status of the last message in channel.
    open private(set) lazy var readStatusView: _ChatChannelReadStatusCheckmarkView<ExtraData> = uiConfigSubviews
        .readStatusView.init()
        .withoutAutoresizingMaskConstraints
     */

    override public func defaultAppearance() {
        super.defaultAppearance()

        backgroundColor = uiConfig.colorPalette.background

        titleLabel.font = uiConfig.font.bodyBold

        subtitleLabel.textColor = uiConfig.colorPalette.subtitleText
        subtitleLabel.font = uiConfig.font.footnote
        
        timestampLabel.textColor = uiConfig.colorPalette.subtitleText
        timestampLabel.font = uiConfig.font.footnote
    }

    override open func setUpLayout() {
        super.setUpLayout()
        
        cellContentView.addSubview(titleLabel)
        cellContentView.addSubview(subtitleLabel)
        cellContentView.addSubview(timestampLabel)
        cellContentView.addSubview(avatarView)
        cellContentView.addSubview(unreadCountView)
        
        var constraintsToActivate: [NSLayoutConstraint] = []
        
        // A helper layout guide that helps to visually center views around the vertical center of the cell
        // with defined vertical spacing
        let visualCenterGuide = UILayoutGuide()
        cellContentView.addLayoutGuide(visualCenterGuide)
        
        // Helper vertical center layout guide
        constraintsToActivate += [
            // Pin the center guide to the vertical center
            visualCenterGuide.centerYAnchor.pin(equalTo: cellContentView.centerYAnchor),
            
            // Set its height to the current vertical margin to match the current spacing
            visualCenterGuide.heightAnchor.pin(equalToConstant: layoutMargins.top)
        ]
        
        // Avatar view
        constraintsToActivate += [
            // Default avatar view size
            avatarView.heightAnchor.pin(equalToConstant: 48),
            
            // Pin size/width ratio to 1:1
            avatarView.widthAnchor.pin(equalTo: avatarView.heightAnchor),
            
            // Align avatar to the left
            avatarView.leadingAnchor.pin(equalTo: cellContentView.layoutMarginsGuide.leadingAnchor),
            
            // Always center the avatar vertically
            avatarView.centerYAnchor.pin(equalTo: visualCenterGuide.centerYAnchor),
            
            // Avatar top and bottom should always be inside the cell
            avatarView.topAnchor.pin(greaterThanOrEqualTo: cellContentView.layoutMarginsGuide.topAnchor),
            avatarView.bottomAnchor.pin(lessThanOrEqualTo: cellContentView.layoutMarginsGuide.bottomAnchor)
        ]
        
        // Title label
        constraintsToActivate += [
            // Bottom of the label is aligned with avatar vertical center
            titleLabel.lastBaselineAnchor.pin(equalTo: visualCenterGuide.topAnchor),

            // Pin the title label leading anchor to avatar's trailing + spacing
            titleLabel.leadingAnchor.pin(equalToSystemSpacingAfter: avatarView.trailingAnchor),
            
            // Title label top should always be inside the cell
            titleLabel.topAnchor.pin(greaterThanOrEqualTo: cellContentView.layoutMarginsGuide.topAnchor)
        ]

        // Subtitle label
        constraintsToActivate += [
            // Top of the label is aligned with avatar vertical center
            subtitleLabel.topAnchor.pin(equalTo: visualCenterGuide.bottomAnchor),
            
            // Pin the subtitle label leading anchor to avatar's trailing + spacing
            subtitleLabel.leadingAnchor.pin(equalToSystemSpacingAfter: avatarView.trailingAnchor)
        ]

        // Unread count view
        constraintsToActivate += [
            // Pin the label to the trailing anchor
            unreadCountView.trailingAnchor.pin(equalTo: cellContentView.layoutMarginsGuide.trailingAnchor),
            
            // Align it vertically with the title
            unreadCountView.centerYAnchor.pin(equalTo: titleLabel.centerYAnchor),
            
            // Title label shouldn't overlap
            unreadCountView.leadingAnchor.pin(greaterThanOrEqualToSystemSpacingAfter: titleLabel.trailingAnchor)
        ]

        // Timestamp label
        constraintsToActivate += [
            // Pin the label to the trailing anchor
            timestampLabel.trailingAnchor.pin(equalTo: cellContentView.layoutMarginsGuide.trailingAnchor),
            
            // Align it vertically with the subtitle
            timestampLabel.centerYAnchor.pin(equalTo: subtitleLabel.centerYAnchor),
        
            // Subtitle label shouldn't overlap
            timestampLabel.leadingAnchor.pin(greaterThanOrEqualToSystemSpacingAfter: subtitleLabel.trailingAnchor)
        ]
        
        NSLayoutConstraint.activate(constraintsToActivate)
    }
    
    override open func updateContent() {
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
