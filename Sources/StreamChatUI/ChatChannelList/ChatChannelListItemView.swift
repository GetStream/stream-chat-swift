//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// An `UIView` subclass that shows summary and preview information about a given channel.
open class ChatChannelListItemView: _View, ThemeProvider, SwiftUIRepresentable {
    /// The content of this view.
    public struct Content {
        /// Channel for the current Item.
        public let channel: ChatChannel
        /// Current user ID needed to filter out when showing typing indicator.
        public let currentUserId: UserId?
        
        public init(channel: ChatChannel, currentUserId: UserId?) {
            self.channel = channel
            self.currentUserId = currentUserId
        }
    }
    
    /// The data this view component shows.
    public var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    /// A formatter that converts the message timestamp to textual representation.
    public lazy var timestampFormatter: MessageTimestampFormatter = appearance.formatters.messageTimestamp

    /// Main container which holds `avatarView` and two horizontal containers `title` and `unreadCount` and
    /// `subtitle` and `timestampLabel`
    open private(set) lazy var mainContainer: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "mainContainer")
    
    /// This container embeded by `mainContainer` containing `topContainer` and `bottomContainer`.
    open private(set) lazy var rightContainer: ContainerStackView = ContainerStackView(
        axis: .vertical,
        spacing: 4
    )
    .withoutAutoresizingMaskConstraints
    .withAccessibilityIdentifier(identifier: "rightContainer")

    /// By default contains `title` and `unreadCount`.
    /// This container is embed inside `mainContainer ` and is the one above `bottomContainer`
    open private(set) lazy var topContainer: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "topContainer")

    /// By default contains `subtitle` and `timestampLabel`.
    /// This container is embed inside `mainContainer ` and is the one below `topContainer`
    open private(set) lazy var bottomContainer: ContainerStackView = ContainerStackView(alignment: .center, spacing: 4)
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "bottomContainer")
    
    /// The `UILabel` instance showing the channel name.
    open private(set) lazy var titleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withAccessibilityIdentifier(identifier: "titleLabel")
    
    /// The `UILabel` instance showing the last message or typing users if any.
    open private(set) lazy var subtitleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withAccessibilityIdentifier(identifier: "subtitleLabel")
    
    /// The `UILabel` instance showing the time of the last sent message.
    open private(set) lazy var timestampLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withAccessibilityIdentifier(identifier: "timestampLabel")
    
    /// The view used to show channels avatar.
    open private(set) lazy var avatarView: ChatChannelAvatarView = components
        .channelAvatarView
        .init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "avatarView")
    
    /// The view showing number of unread messages in channel if any.
    open private(set) lazy var unreadCountView: ChatChannelUnreadCountView = components
        .channelUnreadCountView.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "unreadCountView")

    /// Text of `titleLabel` which contains the channel name.
    open var titleText: String? {
        if let channel = content?.channel {
            return appearance.formatters.channelName.format(channel: channel, forCurrentUserId: channel.membership?.id)
        } else {
            return nil
        }
    }

    /// Text of `subtitleLabel` which contains current typing user or the last message in the channel.
    open var subtitleText: String? {
        guard let content = content else { return nil }
        if let typingUsersInfo = typingUserString {
            return typingUsersInfo
        } else if let previewMessage = content.channel.previewMessage {
            guard previewMessage.type != .system else {
                return previewMessage.text
            }
            
            let authorName = previewMessage.isSentByCurrentUser
                ? L10n.you
                : previewMessage.author.name ?? previewMessage.author.id
            
            let text = previewMessage.textContent ?? previewMessage.text
            
            return "\(authorName): \(text)"
        } else {
            return L10n.Channel.Item.emptyMessages
        }
    }

    /// Text of `timestampLabel` which contains the time of the last sent message.
    open var timestampText: String? {
        if let timestamp = content?.channel.previewMessage?.createdAt {
            return timestampFormatter.format(timestamp)
        } else {
            return nil
        }
    }
    
    /// The delivery status to be shown for the channel's preview message.
    open var previewMessageDeliveryStatus: MessageDeliveryStatus? {
        guard
            let content = content,
            let deliveryStatus = content.channel.previewMessage?.deliveryStatus
        else { return nil }
        
        switch deliveryStatus {
        case .pending, .failed:
            return deliveryStatus
        case .sent, .read:
            guard content.channel.config.readEventsEnabled else { return nil }
            
            return deliveryStatus
        default:
            return nil
        }
    }

    /// The indicator the delivery status of the channel preview message.
    open private(set) lazy var previewMessageDeliveryStatusView = components
        .messageDeliveryStatusCheckmarkView.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "previewMessageDeliveryStatusView")
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = appearance.colorPalette.background

        titleLabel.font = appearance.fonts.bodyBold

        subtitleLabel.textColor = appearance.colorPalette.subtitleText
        subtitleLabel.font = appearance.fonts.footnote
        
        timestampLabel.textColor = appearance.colorPalette.subtitleText
        timestampLabel.font = appearance.fonts.footnote
    }

    override open func setUpLayout() {
        super.setUpLayout()

        /// Default layout:
        /// ```
        /// |----------------------------------------------------|
        /// |            | titleLabel          | unreadCountView |
        /// | avatarView | --------------------------------------|
        /// |            | subtitleLabel        | timestampLabel |
        /// |----------------------------------------------------|
        /// ```
        
        topContainer.addArrangedSubviews([
            titleLabel.flexible(axis: .horizontal), unreadCountView
        ])

        bottomContainer.addArrangedSubviews([
            subtitleLabel.flexible(axis: .horizontal), timestampLabel
        ])
        
        rightContainer.addArrangedSubviews([
            topContainer, bottomContainer
        ])

        NSLayoutConstraint.activate([
            avatarView.heightAnchor.pin(equalToConstant: 48),
            avatarView.widthAnchor.pin(equalTo: avatarView.heightAnchor)
        ])

        mainContainer.addArrangedSubviews([
            avatarView,
            rightContainer
        ])
        
        mainContainer.alignment = .center
        mainContainer.isLayoutMarginsRelativeArrangement = true
        
        timestampLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        embed(mainContainer)
    }
    
    override open func updateContent() {
        titleLabel.text = titleText
        subtitleLabel.text = subtitleText
        timestampLabel.text = timestampText

        avatarView.content = (content?.channel, content?.currentUserId)

        unreadCountView.content = content?.channel.unreadCount ?? .noUnread
        unreadCountView.invalidateIntrinsicContentSize()
        
        let checkmarkContent = previewMessageDeliveryStatus.map {
            ChatMessageDeliveryStatusCheckmarkView.Content(deliveryStatus: $0)
        }
        previewMessageDeliveryStatusView.content = checkmarkContent
        previewMessageDeliveryStatusView.isHidden = checkmarkContent == nil
        
        if let status = checkmarkContent?.deliveryStatus {
            bottomContainer.insertArrangedSubview(
                previewMessageDeliveryStatusView,
                at: status == .pending || status == .failed ? 0 : 1
            )
        }
    }
}

extension ChatChannelListItemView {
    /// The formatted string containing the typing member.
    var typingUserString: String? {
        guard let users = content?.channel.currentlyTypingUsers.filter({ $0.id != content?.currentUserId }),
              !users.isEmpty
        else { return nil }

        let names = users
            .compactMap(\.name)
            .sorted()
            .joined(separator: ", ")

        let typingSingularText = L10n.Channel.Item.typingSingular
        let typingPluralText = L10n.Channel.Item.typingPlural

        return names + " \(users.count == 1 ? typingSingularText : typingPluralText)"
    }
}
