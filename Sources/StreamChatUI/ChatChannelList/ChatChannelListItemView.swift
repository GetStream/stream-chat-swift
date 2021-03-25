//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// An `UIView` subclass that shows summary and preview information about a given channel.
public typealias ChatChannelListItemView = _ChatChannelListItemView<NoExtraData>

/// An `UIView` subclass that shows summary and preview information about a given channel.
open class _ChatChannelListItemView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider, SwiftUIRepresentable {
    /// The data this view component shows.
    public var content: (channel: _ChatChannel<ExtraData>?, currentUserId: UserId?) {
        didSet { updateContentIfNeeded() }
    }

    /// The date formatter of the `timestampLabel`
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    
    /// Properties tied to `ChatChannelListItemView` layout
    public struct Layout {
        /// Constraints of `timestampLabel`
        public fileprivate(set) var timestampLabelConstraints: [NSLayoutConstraint] = []
        /// Constraints of `avatarView`
        public fileprivate(set) var avatarViewConstraints: [NSLayoutConstraint] = []
        /// Constraints of `titleLabel`
        public fileprivate(set) var titleLabelConstraints: [NSLayoutConstraint] = []
        /// Constraints of `subtitleLabel`
        public fileprivate(set) var subtitleLabelConstraints: [NSLayoutConstraint] = []
        /// Constraints of `unreadCountView`
        public fileprivate(set) var unreadCountViewConstraints: [NSLayoutConstraint] = []
    }
    
    /// The `UILabel` instance showing the channel name.
    open private(set) lazy var titleLabel: UILabel = uiConfig
        .channelList
        .itemSubviews
        .titleLabel
        .init()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
    
    /// The `UILabel` instance showing the last message or typing members if any.
    open private(set) lazy var subtitleLabel: UILabel = uiConfig
        .channelList
        .itemSubviews
        .subtitleLabel
        .init()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
    
    /// The `UILabel` instance showing the time of the last sent message.
    open private(set) lazy var timestampLabel: UILabel = uiConfig
        .channelList
        .itemSubviews
        .timestampLabel
        .init()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
    
    /// The view used to show channels avatar.
    open private(set) lazy var avatarView: _ChatChannelAvatarView<ExtraData> = uiConfig
        .channelList
        .itemSubviews
        .avatarView
        .init()
        .withoutAutoresizingMaskConstraints
    
    /// The view showing number of unread messages in channel if any.
    open private(set) lazy var unreadCountView: _ChatChannelUnreadCountView<ExtraData> = uiConfig
        .channelList
        .itemSubviews
        .unreadCountView.init()
        .withoutAutoresizingMaskConstraints

    /// Text of `titleLabel` which contains the channel name.
    open var titleText: String? {
        if let channel = content.channel {
            return uiConfig.channelList.channelNamer(channel, content.currentUserId)
        } else {
            return nil
        }
    }

    /// Text of `subtitleLabel` which contains current typing member or the last message in the channel.
    open var subtitleText: String? {
        guard let channel = content.channel else { return nil }
        if let typingMembersInfo = typingMemberString {
            return typingMembersInfo
        } else if let latestMessage = channel.lastMessage {
            return "\(latestMessage.author.name ?? latestMessage.author.id): \(latestMessage.text)"
        } else {
            return L10n.Channel.Item.emptyMessages
        }
    }

    /// Text of `timestampLabel` which contains the time of the last sent message.
    open var timestampText: String? {
        if let lastMessageAt = content.channel?.lastMessageAt {
            return dateFormatter.string(from: lastMessageAt)
        } else {
            return nil
        }
    }

    /// Layout properties of this view
    public private(set) var layout = Layout()

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
        
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(timestampLabel)
        addSubview(avatarView)
        addSubview(unreadCountView)
        
        // A helper layout guide that helps to visually center views around the vertical center of the cell
        // with defined vertical spacing
        let visualCenterGuide = UILayoutGuide()
        addLayoutGuide(visualCenterGuide)
        
        // Helper vertical center layout guide
        NSLayoutConstraint.activate([
            // Pin the center guide to the vertical center
            visualCenterGuide.centerYAnchor.pin(equalTo: centerYAnchor),
            
            // Set its height to the current vertical margin to match the current spacing
            visualCenterGuide.heightAnchor.pin(equalToConstant: layoutMargins.top)
        ])
        
        // Avatar view
        layout.avatarViewConstraints = [
            // Default avatar view size
            avatarView.heightAnchor.pin(equalToConstant: 48),
            
            // Pin size/width ratio to 1:1
            avatarView.widthAnchor.pin(equalTo: avatarView.heightAnchor),
            
            // Align avatar to the left
            avatarView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            
            // Always center the avatar vertically
            avatarView.centerYAnchor.pin(equalTo: visualCenterGuide.centerYAnchor),
            
            // Avatar top and bottom should always be inside the cell
            avatarView.topAnchor.pin(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
            avatarView.bottomAnchor.pin(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor)
        ]
        
        // Title label
        layout.titleLabelConstraints = [
            // Bottom of the label is aligned with avatar vertical center
            titleLabel.lastBaselineAnchor.pin(equalTo: visualCenterGuide.topAnchor),
            
            // Pin the title label leading anchor to avatar's trailing + spacing
            titleLabel.leadingAnchor.pin(equalToSystemSpacingAfter: avatarView.trailingAnchor),
            
            // Title label top should always be inside the cell
            titleLabel.topAnchor.pin(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor)
        ]

        // Subtitle label
        layout.subtitleLabelConstraints = [
            // Top of the label is aligned with avatar vertical center
            subtitleLabel.topAnchor.pin(equalTo: visualCenterGuide.bottomAnchor),
            
            // Pin the subtitle label leading anchor to avatar's trailing + spacing
            subtitleLabel.leadingAnchor.pin(equalToSystemSpacingAfter: avatarView.trailingAnchor)
        ]

        // Unread count view
        layout.unreadCountViewConstraints = [
            // Pin the label to the trailing anchor
            unreadCountView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            
            // Align it vertically with the title
            unreadCountView.centerYAnchor.pin(equalTo: titleLabel.centerYAnchor),
            
            // Title label shouldn't overlap
            unreadCountView.leadingAnchor.pin(greaterThanOrEqualToSystemSpacingAfter: titleLabel.trailingAnchor)
        ]

        // Set titleLabel compression resistance smaller than the unread count view
        titleLabel.setContentCompressionResistancePriority(.streamLow, for: .horizontal)
        unreadCountView.setContentCompressionResistancePriority(.streamRequire, for: .horizontal)

        // Timestamp label
        layout.timestampLabelConstraints = [
            // Pin the label to the trailing anchor
            timestampLabel.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            
            // Align it vertically with the subtitle
            timestampLabel.centerYAnchor.pin(equalTo: subtitleLabel.centerYAnchor),
            
            // Subtitle label shouldn't overlap
            timestampLabel.leadingAnchor.pin(greaterThanOrEqualToSystemSpacingAfter: subtitleLabel.trailingAnchor)
        ]

        // Set subtitleLabel compression resistance smaller than the timestamp label
        subtitleLabel.setContentCompressionResistancePriority(.streamLow, for: .horizontal)
        timestampLabel.setContentCompressionResistancePriority(.streamRequire, for: .horizontal)

        NSLayoutConstraint.activate(
            layout.avatarViewConstraints
                + layout.timestampLabelConstraints
                + layout.titleLabelConstraints
                + layout.subtitleLabelConstraints
                + layout.unreadCountViewConstraints
        )
    }
    
    override open func updateContent() {
        titleLabel.text = titleText
        subtitleLabel.text = subtitleText
        timestampLabel.text = timestampText

        avatarView.content = content

        unreadCountView.content = content.channel?.unreadCount ?? .noUnread
        unreadCountView.invalidateIntrinsicContentSize()
    }
}

extension _ChatChannelListItemView {
    /// The formatted string containing the typing member.
    var typingMemberString: String? {
        guard let members = content.channel?.currentlyTypingMembers, !members.isEmpty else { return nil }

        let names = members
            .compactMap(\.name)
            .sorted()
            .joined(separator: ", ")

        let typingSingularText = L10n.Channel.Item.typingSingular
        let typingPluralText = L10n.Channel.Item.typingPlural

        return names + " \(members.count == 1 ? typingSingularText : typingPluralText)"
    }
}
