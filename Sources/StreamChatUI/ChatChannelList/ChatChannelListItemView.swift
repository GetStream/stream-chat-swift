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
    public var content: _ChatChannel<ExtraData>? {
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
        if let channel = content {
            return uiConfig.channelList.channelNamer(channel, channel.membership?.id)
        } else {
            return nil
        }
    }

    /// Text of `subtitleLabel` which contains current typing member or the last message in the channel.
    open var subtitleText: String? {
        guard let channel = content else { return nil }
        if let typingMembersInfo = typingMemberString {
            return typingMembersInfo
        } else if let latestMessage = channel.latestMessages.first {
            return "\(latestMessage.author.name ?? latestMessage.author.id): \(latestMessage.text)"
        } else {
            return L10n.Channel.Item.emptyMessages
        }
    }

    /// Text of `timestampLabel` which contains the time of the last sent message.
    open var timestampText: String? {
        if let lastMessageAt = content?.lastMessageAt {
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
        backgroundColor = uiConfig.colorPalette.background

        titleLabel.font = uiConfig.font.bodyBold

        subtitleLabel.textColor = uiConfig.colorPalette.subtitleText
        subtitleLabel.font = uiConfig.font.footnote
        
        timestampLabel.textColor = uiConfig.colorPalette.subtitleText
        timestampLabel.font = uiConfig.font.footnote
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
        titleLabel.text = titleText
        subtitleLabel.text = subtitleText
        timestampLabel.text = timestampText

        avatarView.content = (content, content?.membership?.id)

        unreadCountView.content = content?.unreadCount ?? .noUnread
        unreadCountView.invalidateIntrinsicContentSize()
    }
}

extension _ChatChannelListItemView {
    /// The formatted string containing the typing member.
    var typingMemberString: String? {
        guard let members = content?.currentlyTypingMembers, !members.isEmpty else { return nil }

        let names = members
            .compactMap(\.name)
            .sorted()
            .joined(separator: ", ")

        let typingSingularText = L10n.Channel.Item.typingSingular
        let typingPluralText = L10n.Channel.Item.typingPlural

        return names + " \(members.count == 1 ? typingSingularText : typingPluralText)"
    }
}
