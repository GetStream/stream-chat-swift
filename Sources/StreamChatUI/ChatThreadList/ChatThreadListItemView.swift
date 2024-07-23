//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view that displays the thread information in the Thread List.
///
/// Default layout:
/// ```
/// |----------------------------------------------------------|
/// | icon | threadTitleLabel                                  |
/// | ---------------------------------------------------------|
/// | threadDescriptionLabel                 | unreadCountView |
/// |----------------------------------------------------------|
/// |            | replyTitleLabel                             |
/// | avatarView | --------------------------------------------|
/// |            | replyDescriptionLabel      | timestampLabel |
/// |----------------------------------------------------------|
/// ```
open class ChatThreadListItemView: _View, ThemeProvider {
    // MARK: - Content

    /// The content of this view.
    public struct Content {
        /// The thread for the current Item.
        public let thread: ChatThread

        /// The current user ID.
        public let currentUserId: UserId?

        public init(
            thread: ChatThread,
            currentUserId: UserId?
        ) {
            self.thread = thread
            self.currentUserId = currentUserId
        }
    }

    /// The data this view component shows.
    public var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Configuration

    /// The item's view background color.
    open var contentBackgroundColor: UIColor {
        appearance.colorPalette.background
    }

    /// The item's view background color when highlighted.
    open var contentHighlightedBackgroundColor: UIColor {
        appearance.colorPalette.highlightedBackground
    }

    // MARK: - Views

    /// The main stack view which by default contains a top container and a bottom container.
    /// The top container displays thread information and the bottom container displays the latest reply information.
    open private(set) lazy var mainContainer = UIStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "mainContainer")

    // MARK: Thread Container Views

    /// The thread container that by default displays the thread information at the top of the item view.
    open private(set) lazy var threadContainer = UIStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "threadContainer")

    /// An helper container that by default holds the thread icon and the channel name which the thread belongs.
    open private(set) lazy var threadTitleContainer = UIStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "threadTitleContainer")

    /// An image view that shows the thread icon.
    open private(set) lazy var threadIconView = UIImageView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "threadIconView")

    /// A label that by default shows the channel name which the thread belongs to.
    open private(set) lazy var threadTitleLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withAccessibilityIdentifier(identifier: "threadTitleLabel")

    /// An helper container that by default holds the thread description and thread unread count.
    open private(set) lazy var threadDescriptionContainer = UIStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "threadDescriptionContainer")

    /// A label that by default shows the parent message text which is the root of the thread.
    open private(set) lazy var threadDescriptionLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withAccessibilityIdentifier(identifier: "threadDescriptionLabel")

    /// The view showing number of unread replies in the thread.
    open private(set) lazy var threadUnreadCountView: ChatThreadUnreadCountView = components
        .threadUnreadCountView.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "threadUnreadCountView")

    // MARK: Reply Container Views

    /// The reply container that by default displays the latest reply information at the bottom of the item view.
    open private(set) lazy var replyContainer = UIStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "replyContainer")

    /// The view used to show the user avatar of the latest thread reply author.
    open private(set) lazy var replyAuthorAvatarView: ChatUserAvatarView = components
        .userAvatarView
        .init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "replyAuthorAvatarView")

    /// A container that by default displays the text information of the latest reply, including
    /// the author's name, the reply text and the timestamp.
    open private(set) lazy var replyInfoContainer = UIStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "replyInfoContainer")

    /// The label that by default shows the name of the latest reply author.
    open private(set) lazy var replyTitleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withAccessibilityIdentifier(identifier: "replyTitleLabel")

    /// A container that by default holds the latest reply text and the timestamp.
    open private(set) lazy var replyDescriptionContainer = UIStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "replyDescriptionContainer")

    /// The label that by default shows the text of the latest reply.
    open private(set) lazy var replyDescriptionLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withAccessibilityIdentifier(identifier: "replyDescriptionLabel")

    /// The label that by default shows the time of the last reply.
    open private(set) lazy var replyTimestampLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withAccessibilityIdentifier(identifier: "replyTimestampLabel")

    override open func setUpAppearance() {
        super.setUpAppearance()
        
        backgroundColor = contentBackgroundColor

        threadTitleLabel.textColor = appearance.colorPalette.text
        threadTitleLabel.font = appearance.fonts.subheadlineBold

        replyTitleLabel.textColor = appearance.colorPalette.text
        replyTitleLabel.font = appearance.fonts.subheadlineBold

        threadDescriptionLabel.textColor = appearance.colorPalette.subtitleText
        threadDescriptionLabel.font = appearance.fonts.footnote

        replyDescriptionLabel.textColor = appearance.colorPalette.subtitleText
        replyDescriptionLabel.font = appearance.fonts.footnote

        replyTimestampLabel.textColor = appearance.colorPalette.subtitleText
        replyTimestampLabel.font = appearance.fonts.footnote
        
        threadIconView.tintColor = appearance.colorPalette.text
        threadIconView.image = appearance.images.threadIcon

        threadUnreadCountView.layoutMargins = .init(top: 3, left: 4, bottom: 3, right: 4)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        directionalLayoutMargins = .init(
            top: 12,
            leading: 8,
            bottom: 12,
            trailing: 8
        )

        addSubview(mainContainer)
        mainContainer.pin(to: layoutMarginsGuide)
        mainContainer.axis = .vertical
        mainContainer.spacing = 8

        // Top container that holds the thread information
        mainContainer.addArrangedSubview(threadContainer)
        threadContainer.axis = .vertical
        threadContainer.spacing = 2
        threadContainer.addArrangedSubview(threadTitleContainer)
        threadContainer.addArrangedSubview(threadDescriptionContainer)
        threadTitleContainer.axis = .horizontal
        threadTitleContainer.spacing = 4
        threadTitleContainer.addArrangedSubview(threadIconView)
        threadTitleContainer.addArrangedSubview(threadTitleLabel)
        threadDescriptionContainer.axis = .horizontal
        threadDescriptionContainer.alignment = .center
        threadDescriptionContainer.addArrangedSubview(threadDescriptionLabel)
        threadDescriptionContainer.addArrangedSubview(UIView())
        threadDescriptionContainer.addArrangedSubview(threadUnreadCountView)

        // Bottom container that holds the latest thread reply information.
        mainContainer.addArrangedSubview(replyContainer)
        replyContainer.axis = .horizontal
        replyContainer.spacing = 4
        replyContainer.addArrangedSubview(replyAuthorAvatarView)
        replyContainer.addArrangedSubview(replyInfoContainer)
        replyInfoContainer.axis = .vertical
        replyInfoContainer.addArrangedSubview(replyTitleLabel)
        replyInfoContainer.addArrangedSubview(replyDescriptionContainer)
        replyDescriptionContainer.axis = .horizontal
        replyDescriptionContainer.addArrangedSubview(replyDescriptionLabel)
        replyDescriptionContainer.addArrangedSubview(UIView())
        replyDescriptionContainer.addArrangedSubview(replyTimestampLabel)

        NSLayoutConstraint.activate([
            threadDescriptionContainer.heightAnchor.pin(greaterThanOrEqualToConstant: 22),
            replyAuthorAvatarView.heightAnchor.pin(equalToConstant: 40),
            replyAuthorAvatarView.widthAnchor.pin(equalTo: replyAuthorAvatarView.heightAnchor),
            threadIconView.heightAnchor.pin(equalToConstant: 15),
            threadIconView.widthAnchor.pin(equalTo: threadIconView.heightAnchor)
        ])

        replyTimestampLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else {
            return
        }

        let thread = content.thread
        let latestReply = thread.latestReplies.last
        let unreadReplies = thread.reads.first(where: { $0.user.id == content.currentUserId })?.unreadMessagesCount ?? 0

        threadTitleLabel.text = channelNameText
        threadDescriptionLabel.text = parentMessagePreviewText.map { L10n.ThreadListItem.repliedTo($0) }
        replyDescriptionLabel.text = replyPreviewText
        replyTimestampLabel.text = replyTimestampLabelText
        replyAuthorAvatarView.content = latestReply?.author
        replyTitleLabel.text = latestReply?.author.name
        threadUnreadCountView.content = unreadReplies
    }

    /// The timestamp text formatted.
    open var replyTimestampLabelText: String? {
        content?.thread.latestReplies.last.map {
            appearance.formatters.threadListMessageTimestamp.format($0.createdAt)
        }
    }

    /// The channel name formatted.
    open var channelNameText: String? {
        guard let content = self.content else {
            return nil
        }

        return appearance.formatters.channelName.format(
            channel: content.thread.channel,
            forCurrentUserId: content.currentUserId
        )
    }

    /// The parent message preview text.
    open var parentMessagePreviewText: String? {
        guard let thread = content?.thread else { return nil }
        
        var parentMessageText: String
        if thread.parentMessage.isDeleted {
            parentMessageText = L10n.Message.Item.deleted
        } else {
            parentMessageText = thread.title ?? thread.parentMessage.text
        }
        
        if parentMessageText.isEmpty {
            parentMessageText = thread.parentMessage.allAttachments.first?.type.rawValue ?? ""
        }

        return parentMessageText
    }

    /// The reply preview text.
    open var replyPreviewText: String? {
        // TODO: On v5 the logic in ChatChannelItemView.subtitleText should be extracted to `Appearance.formatters` and shared with the `ChatThreadListItemView`
        guard let latestReply = content?.thread.latestReplies.last else {
            return nil
        }
        
        if latestReply.text.isEmpty {
            return latestReply.allAttachments.first?.type.rawValue
        }

        if latestReply.isDeleted {
            return L10n.Message.Item.deleted
        }

        return latestReply.text
    }
}
