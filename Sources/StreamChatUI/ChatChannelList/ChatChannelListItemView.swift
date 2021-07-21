//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// An `UIView` subclass that shows summary and preview information about a given channel.
public typealias ChatChannelListItemView = _ChatChannelListItemView<NoExtraData>

/// An `UIView` subclass that shows summary and preview information about a given channel.
open class _ChatChannelListItemView<ExtraData: ExtraDataTypes>: _View, ThemeProvider, SwiftUIRepresentable {
    /// The content of this view.
    public struct Content {
        /// Channel for the current Item.
        public let channel: _ChatChannel<ExtraData>
        /// Current user ID needed to filter out when showing typing indicator.
        public let currentUserId: UserId?
        
        public init(channel: _ChatChannel<ExtraData>, currentUserId: UserId?) {
            self.channel = channel
            self.currentUserId = currentUserId
        }
    }
    
    /// The data this view component shows.
    public var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    /// The date formatter of the `timestampLabel`
    public lazy var dateFormatter: DateFormatter = .makeDefault()

    /// Main container which holds `avatarView` and two horizontal containers `title` and `unreadCount` and
    /// `subtitle` and `timestampLabel`
    open private(set) lazy var mainContainer: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints

    /// By default contains `title` and `unreadCount`.
    /// This container is embed inside `mainContainer ` and is the one above `bottomContainer`
    open private(set) lazy var topContainer: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints

    /// By default contains `subtitle` and `timestampLabel`.
    /// This container is embed inside `mainContainer ` and is the one below `topContainer`
    open private(set) lazy var bottomContainer: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints
    
    /// The `UILabel` instance showing the channel name.
    open private(set) lazy var titleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
    
    /// The `UILabel` instance showing the last message or typing users if any.
    open private(set) lazy var subtitleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
    
    /// The `UILabel` instance showing the time of the last sent message.
    open private(set) lazy var timestampLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
    
    /// The view used to show channels avatar.
    open private(set) lazy var avatarView: _ChatChannelAvatarView<ExtraData> = components
        .channelAvatarView
        .init()
        .withoutAutoresizingMaskConstraints
    
    /// The view showing number of unread messages in channel if any.
    open private(set) lazy var unreadCountView: ChatChannelUnreadCountView = components
        .channelUnreadCountView.init()
        .withoutAutoresizingMaskConstraints

    /// Text of `titleLabel` which contains the channel name.
    open var titleText: String? {
        if let channel = content?.channel {
            return components.channelNamer(channel, channel.membership?.id)
        } else {
            return nil
        }
    }

    /// Text of `subtitleLabel` which contains current typing user or the last message in the channel.
    open var subtitleText: String? {
        guard let content = content else { return nil }
        if let typingUsersInfo = typingUserString {
            return typingUsersInfo
        } else if let latestMessage = content.channel.latestMessages.first {
            return "\(latestMessage.author.name ?? latestMessage.author.id): \(latestMessage.text)"
        } else {
            return L10n.Channel.Item.emptyMessages
        }
    }

    /// Text of `timestampLabel` which contains the time of the last sent message.
    open var timestampText: String? {
        if let lastMessageAt = content?.channel.lastMessageAt {
            return dateFormatter.string(from: lastMessageAt)
        } else {
            return nil
        }
    }

    /*
         TODO: ReadStatusView, Missing LLC API
     /// The view showing indicator for read status of the last message in channel.
     open private(set) lazy var readStatusView: _ChatChannelReadStatusCheckmarkView<ExtraData> = uiConfigSubviews
         .readStatusView.init()
         .withoutAutoresizingMaskConstraints
      */

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

        NSLayoutConstraint.activate([
            avatarView.heightAnchor.pin(equalToConstant: 48),
            avatarView.widthAnchor.pin(equalTo: avatarView.heightAnchor)
        ])

        mainContainer.addArrangedSubviews([
            avatarView,
            ContainerStackView(
                axis: .vertical,
                spacing: 4,
                arrangedSubviews: [topContainer, bottomContainer]
            )
        ])
        
        mainContainer.alignment = .center
        mainContainer.isLayoutMarginsRelativeArrangement = true
        
        embed(mainContainer)
    }
    
    override open func updateContent() {
        if let subtitleText = subtitleText {
            if appearance.isMarkdownEnabled,
               let markdown = MarkdownParser.makeMarkdownText(from: subtitleText) {
                markdown.applyForegroundColor(appearance.colorPalette.subtitleText)
                subtitleLabel.attributedText = markdown.with(font: appearance.fonts.footnote)
            } else {
                subtitleLabel.text = subtitleText
            }
        }

        titleLabel.text = titleText
        timestampLabel.text = timestampText

        avatarView.content = (content?.channel, content?.currentUserId)

        unreadCountView.content = content?.channel.unreadCount ?? .noUnread
        unreadCountView.invalidateIntrinsicContentSize()
    }
}

extension _ChatChannelListItemView {
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
