//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The channel item view that displays information in a channel list cell.
open class ChatChannelListItemView: _View, ThemeProvider, SwiftUIRepresentable {
    /// The content of this view.
    public struct Content {
        /// Channel for the current Item.
        public let channel: ChatChannel
        /// Current user ID needed to filter out when showing typing indicator.
        public let currentUserId: UserId?
        /// The result of a search query.
        public let searchResult: SearchResult?

        /// The message part of a search result.
        var searchedMessage: ChatMessage? {
            searchResult?.message
        }

        public init(
            channel: ChatChannel,
            currentUserId: UserId?,
            searchResult: SearchResult? = nil
        ) {
            self.channel = channel
            self.currentUserId = currentUserId
            self.searchResult = searchResult
        }

        /// The additional information as part of a search query.
        public struct SearchResult {
            /// The search query input.
            public let text: String
            /// The message that belongs to a message search result.
            public let message: ChatMessage?
        }
    }

    /// The data this view component shows.
    public var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    /// A formatter that converts the message timestamp to textual representation.
    public lazy var timestampFormatter: MessageTimestampFormatter = appearance.formatters.channelListMessageTimestamp

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

    open private(set) lazy var subtitleContainer: UIStackView = UIStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "topContainer")

    /// The `UILabel` instance showing the last message or typing users if any.
    open private(set) lazy var subtitleImageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "subtitleIcon")

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

    /// The view used to show user avatar in case we are in a search result.
    open private(set) lazy var userAvatarView: ChatUserAvatarView = components
        .userAvatarView
        .init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "userAvatarView")

    /// The view showing number of unread messages in channel if any.
    open private(set) lazy var unreadCountView: ChatChannelUnreadCountView = components
        .channelUnreadCountView.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "unreadCountView")

    /// The prefix text for the draft message.
    open var draftPrefixText: String {
        "\(L10n.Message.Preview.draft):"
    }

    /// Text of `titleLabel` which contains the channel name.
    open var titleText: String? {
        if let searchedMessage = content?.searchedMessage {
            return channelTitleTextForSearchedMessage(searchedMessage)
        }

        if let channel = content?.channel {
            return channelTitleText(for: channel)
        }

        return nil
    }

    /// Text of `subtitleLabel` which contains current typing user or the last message in the channel.
    open var subtitleText: String? {
        guard let content = content else { return nil }

        if let searchedMessage = content.searchedMessage {
            return previewMessageTextForSearchedMessage(messageText: searchedMessage.text)
        }

        if let typingUsersInfo = typingUserString {
            return typingUsersInfo
        }

        if let dratMessage = content.channel.draftMessage.map(ChatMessage.init), components.isDraftMessagesEnabled {
            let previewText = previewMessageContextText(previewMessage: dratMessage)
            return previewMessageTextForDraft(messageText: previewText)
        }

        if let previewMessage = content.channel.previewMessage {
            if previewMessage.type == .system {
                return previewMessageTextForSystemMessage(messageText: previewMessage.text)
            }

            if let pollPreviewText = pollAttachmentPreviewText(for: previewMessage) {
                return pollPreviewText
            }

            let previewText = previewMessageContextText(previewMessage: previewMessage)
            if isLastMessageVoiceRecording {
                return previewText
            }

            if previewMessage.isSentByCurrentUser {
                return previewMessageTextForCurrentUser(messageText: previewText)
            }

            if content.channel.memberCount == 2 {
                return previewMessageTextFor1on1Channel(messageText: previewText)
            }

            return previewMessageTextFromAnotherUser(previewMessage.author, messageText: previewText)
        }

        return previewMessageTextForEmptyMessage()
    }

    open var subtitleIcon: UIImage? {
        isLastMessageVoiceRecording ? appearance.images.mic : nil
    }

    /// Text of `timestampLabel` which contains the time of the last sent message.
    open var timestampText: String? {
        if let searchedMessage = content?.searchedMessage {
            return timestampFormatter.format(searchedMessage.createdAt)
        }
        
        if let timestamp = content?.channel.previewMessage?.createdAt {
            return timestampFormatter.format(timestamp)
        }

        return nil
    }

    /// The delivery status to be shown for the channel's preview message.
    open var previewMessageDeliveryStatus: MessageDeliveryStatus? {
        if content?.searchedMessage != nil {
            // When doing message search, we don't want to display delivery status.
            return nil
        }

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

    /// The item's view background color.
    open var contentBackgroundColor: UIColor {
        appearance.colorPalette.background
    }

    /// The item's view background color when highlighted.
    open var contentHighlightedBackgroundColor: UIColor {
        appearance.colorPalette.highlightedBackground
    }

    /// The indicator the delivery status of the channel preview message.
    open private(set) lazy var previewMessageDeliveryStatusView = components
        .messageDeliveryStatusCheckmarkView.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "previewMessageDeliveryStatusView")

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = contentBackgroundColor

        titleLabel.textColor = appearance.colorPalette.text
        titleLabel.font = appearance.fonts.bodyBold

        subtitleLabel.textColor = appearance.colorPalette.subtitleText
        subtitleLabel.font = appearance.fonts.footnote

        subtitleImageView.tintColor = subtitleLabel.textColor
        subtitleImageView.contentMode = .scaleAspectFit

        timestampLabel.textColor = appearance.colorPalette.subtitleText
        timestampLabel.font = appearance.fonts.footnote
    }

    override open func setUpLayout() {
        super.setUpLayout()

        /// Default layout:
        /// ```
        /// |----------------------------------------------------------|
        /// |            | titleLabel          | unreadCountView       |
        /// | avatarView | --------------------------------------------|
        /// |            | subtitleContainer | Spacer | timestampLabel |
        /// |----------------------------------------------------------|
        /// ```

        topContainer.addArrangedSubviews([
            titleLabel.flexible(axis: .horizontal), unreadCountView
        ])

        subtitleContainer.axis = .horizontal
        subtitleContainer.spacing = 4
        subtitleContainer.alignment = .center
        subtitleContainer.addArrangedSubview(subtitleLabel)
        subtitleContainer.addArrangedSubview(UIView().flexible(axis: .horizontal))

        bottomContainer.addArrangedSubviews([
            subtitleContainer, timestampLabel
        ])

        rightContainer.addArrangedSubviews([
            topContainer, bottomContainer
        ])

        NSLayoutConstraint.activate([
            avatarView.heightAnchor.pin(equalToConstant: 48),
            avatarView.widthAnchor.pin(equalTo: avatarView.heightAnchor),
            userAvatarView.heightAnchor.pin(equalToConstant: 48),
            userAvatarView.widthAnchor.pin(equalTo: userAvatarView.heightAnchor)
        ])

        mainContainer.addArrangedSubviews([
            avatarView,
            userAvatarView,
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
        subtitleImageView.image = subtitleIcon
        if subtitleImageView.image != nil {
            subtitleImageView.heightAnchor.pin(equalToConstant: subtitleLabel.font.pointSize).isActive = true
            subtitleImageView.widthAnchor.pin(equalTo: subtitleImageView.heightAnchor).isActive = true
            subtitleContainer.insertArrangedSubview(subtitleImageView, at: 0)
        } else if subtitleImageView.superview == subtitleContainer {
            subtitleContainer.removeArrangedSubview(subtitleImageView)
        }

        if let searchedMessage = content?.searchedMessage {
            userAvatarView.content = searchedMessage.author
            userAvatarView.isHidden = false
            avatarView.isHidden = true
        } else {
            avatarView.content = (content?.channel, content?.currentUserId)
            avatarView.isHidden = false
            userAvatarView.isHidden = true
        }

        unreadCountView.content = content?.channel.unreadCount ?? .noUnread
        unreadCountView.invalidateIntrinsicContentSize()

        if content?.searchedMessage != nil {
            unreadCountView.content = .noUnread
        }

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

        if content?.channel.draftMessage != nil {
            let highlightOptions = TextHighlightOptions(
                color: appearance.colorPalette.accentPrimary,
                font: appearance.fonts.footnoteBold
            )
            subtitleLabel.highlightText(draftPrefixText, options: highlightOptions)
        }
    }

    // MARK: - Channel title rendering

    /// The channel title text in case the channel is part of a search result.
    open func channelTitleTextForSearchedMessage(_ message: ChatMessage) -> String {
        var title = "\(message.author.name ?? message.author.id)"
        if let channelName = content?.channel.name, !channelName.isEmpty {
            title += L10n.Channel.Item.Search.in(channelName)
        }
        return title
    }

    /// The default channel title text.
    open func channelTitleText(for channel: ChatChannel) -> String? {
        appearance.formatters
            .channelName
            .format(channel: channel, forCurrentUserId: channel.membership?.id)
    }

    // MARK: - Preview message text rendering

    /// The message preview text based solely on the message content.
    /// It does not account if it is sent by the current user or it is a draft etc.
    ///
    /// - Parameter previewMessage: The preview message of the channel.
    /// - Returns: A string representing the message preview text.
    open func previewMessageContextText(previewMessage: ChatMessage) -> String {
        if previewMessage.voiceRecordingAttachments.isEmpty == false {
            return previewMessageForAudioRecordingMessage(messageText: previewMessage.text)
        }

        var text = previewMessage.textContent ?? previewMessage.text
        if let translatedText = translatedPreviewText(for: previewMessage, messageText: text) {
            text = translatedText
        }
        if let attachmentText = attachmentPreviewText(for: previewMessage, messageText: text) {
            text = attachmentText
        }
        return text
    }

    /// The message preview text in case the message is empty.
    /// - Returns:  A string representing the message preview text.
    open func previewMessageTextForEmptyMessage() -> String {
        L10n.Channel.Item.emptyMessages
    }

    /// The message preview text in case the message is an audio recording message.
    /// - Parameter messageText: The current text of the message.
    /// - Returns:  A string representing the message preview text.
    open func previewMessageForAudioRecordingMessage(messageText: String) -> String {
        L10n.ChannelList.Preview.Voice.recording
    }

    /// The message preview text in case the message is a system message.
    /// - Parameter messageText: The current text of the message.
    /// - Returns:  A string representing the message preview text.
    open func previewMessageTextForSystemMessage(messageText: String) -> String {
        messageText
    }

    /// The message preview text in case the message is a search result.
    /// - Parameter messageText: The current text of the message.
    /// - Returns:  A string representing the message preview text.
    open func previewMessageTextForSearchedMessage(messageText: String) -> String {
        messageText
    }

    /// The message preview text in case the message is from the current user.
    /// - Parameter messageText: The current text of the message.
    /// - Returns:  A string representing the message preview text.
    open func previewMessageTextForCurrentUser(messageText: String) -> String {
        "\(L10n.you): \(messageText)"
    }

    /// The message preview text in case the message is a 1on1 channel.
    /// - Parameter messageText: The current text of the message.
    /// - Returns:  A string representing the message preview text.
    open func previewMessageTextFor1on1Channel(messageText: String) -> String {
        messageText
    }

    /// The message preview text in case the message is a draft.
    /// - Parameter messageText: The current text of the message.
    /// - Returns:  A string representing the message preview text.
    open func previewMessageTextForDraft(messageText: String) -> String {
        "\(draftPrefixText) \(messageText)"
    }

    /// The message preview text in case the message is from another user and it is not a 1on1 channel.
    /// - Parameter messageText: The current text of the message.
    /// - Returns:  A string representing the message preview text.
    open func previewMessageTextFromAnotherUser(_ user: ChatUser, messageText: String) -> String {
        let authorName = user.name ?? user.id
        return "\(authorName): \(messageText)"
    }

    /// The message preview text in case the message is translated.
    /// - Parameter previewMessage: The preview message of the channel.
    /// - Parameter messageText: The current text of the message.
    /// - Returns: A string representing the message preview text.
    open func translatedPreviewText(for previewMessage: ChatMessage, messageText: String) -> String? {
        guard let currentUserLang = content?.channel.membership?.language,
              let translatedText = previewMessage.translatedText(for: currentUserLang) else {
            return nil
        }
        return translatedText
    }

    /// The message preview text in case it contains attachments.
    /// - Parameter previewMessage: The preview message of the channel.
    /// - Parameter messageText: The current text of the message.
    /// - Returns: A string representing the message preview text.
    open func attachmentPreviewText(for previewMessage: ChatMessage, messageText: String) -> String? {
        guard let attachment = previewMessage.allAttachments.first else {
            return nil
        }

        let text = messageText
        switch attachment.type {
        case .audio:
            let defaultAudioText = L10n.Channel.Item.audio
            return "🎧 \(text.isEmpty ? defaultAudioText : text)"
        case .file:
            guard let fileAttachment = previewMessage.fileAttachments.first else {
                return nil
            }
            let title = fileAttachment.payload.title
            return "📄 \(title ?? text)"
        case .image:
            let defaultPhotoText = L10n.Channel.Item.photo
            return "📷 \(text.isEmpty ? defaultPhotoText : text)"
        case .video:
            let defaultVideoText = L10n.Channel.Item.video
            return "📹 \(text.isEmpty ? defaultVideoText : text)"
        case .giphy:
            return "/giphy"
        default:
            return nil
        }
    }

    /// The message preview text in case it is a Poll.
    /// - Parameter previewMessage: The preview message of the channel.
    /// - Returns: A string representing the message preview text.
    open func pollAttachmentPreviewText(for previewMessage: ChatMessage) -> String? {
        guard let poll = previewMessage.poll, !previewMessage.isDeleted else { return nil }
        var components = ["📊"]
        if let latestVoter = poll.latestVotes.first?.user {
            if latestVoter.id == content?.currentUserId {
                components.append(L10n.Message.Preview.pollYouVoted)
            } else {
                components.append(L10n.Message.Preview.pollSomeoneVoted(latestVoter.name ?? latestVoter.id))
            }
        } else if let creator = poll.createdBy {
            if previewMessage.isSentByCurrentUser {
                components.append(L10n.Message.Preview.pollYouCreated)
            } else {
                components.append(L10n.Message.Preview.pollSomeoneCreated(creator.name ?? creator.id))
            }
        }
        if !poll.name.isEmpty {
            components.append(poll.name)
        }
        return components.joined(separator: " ")
    }

    // MARK: - Channel preview when user is typing

    /// The formatted string containing the typing member.
    open var typingUserString: String? {
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

extension ChatChannelListItemView {
    var isLastMessageVoiceRecording: Bool {
        let previewMessage = content?.channel.previewMessage
        let previewHasVoiceRecording = previewMessage?.voiceRecordingAttachments.isEmpty == false
        let doesNotHaveDraft = content?.channel.draftMessage == nil
        let noTypingUsers = typingUserString == nil
        return previewHasVoiceRecording && noTypingUsers && doesNotHaveDraft
    }
}
