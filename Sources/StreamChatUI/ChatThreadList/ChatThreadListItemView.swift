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
    open private(set) lazy var threadUnreadCountView: ChatUnreadCountView = components
        .unreadCountView.init()
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
        threadTitleLabel.font = appearance.fonts.bodyBold

        replyTitleLabel.textColor = appearance.colorPalette.text
        replyTitleLabel.font = appearance.fonts.bodyBold

        threadDescriptionLabel.textColor = appearance.colorPalette.subtitleText
        threadDescriptionLabel.font = appearance.fonts.footnote

        replyDescriptionLabel.textColor = appearance.colorPalette.subtitleText
        replyDescriptionLabel.font = appearance.fonts.footnote

        replyTimestampLabel.textColor = appearance.colorPalette.subtitleText
        replyTimestampLabel.font = appearance.fonts.footnote

        threadUnreadCountView.layoutMargins = .init(top: 3, left: 4, bottom: 3, right: 4)
        
        threadIconView.tintColor = appearance.colorPalette.text
        // TODO:
        if #available(iOS 13.0, *) {
            threadIconView.image = UIImage(systemName: "text.bubble")
        } else {
            // Fallback on earlier versions
        }
    }

    override open func setUpLayout() {
        super.setUpLayout()
        
        addSubview(mainContainer)
        mainContainer.pin(to: layoutMarginsGuide)
        mainContainer.axis = .vertical
        mainContainer.spacing = 8

        // Top container that holds the thread information
        mainContainer.addArrangedSubview(threadContainer)
        threadContainer.axis = .vertical
        threadContainer.spacing = 4
        threadContainer.addArrangedSubview(threadTitleContainer)
        threadContainer.addArrangedSubview(threadDescriptionContainer)
        threadTitleContainer.axis = .horizontal
        threadTitleContainer.spacing = 4
        threadTitleContainer.addArrangedSubview(threadIconView)
        threadTitleContainer.addArrangedSubview(threadTitleLabel)
        threadDescriptionContainer.axis = .horizontal
        threadDescriptionContainer.alignment = .center
        threadDescriptionContainer.addArrangedSubview(threadDescriptionLabel.flexible(axis: .horizontal))
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
        replyDescriptionContainer.addArrangedSubview(replyDescriptionLabel.flexible(axis: .horizontal))
        replyDescriptionContainer.addArrangedSubview(replyTimestampLabel)

        NSLayoutConstraint.activate([
            threadDescriptionLabel.heightAnchor.pin(greaterThanOrEqualToConstant: 15)
        ])

        NSLayoutConstraint.activate([
            replyAuthorAvatarView.heightAnchor.pin(equalToConstant: 48),
            replyAuthorAvatarView.widthAnchor.pin(equalTo: replyAuthorAvatarView.heightAnchor)
        ])

        NSLayoutConstraint.activate([
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
        let channel = thread.channel
        let latestReply = thread.latestReplies.last

        let channelName = appearance.formatters.channelName.format(
            channel: channel,
            forCurrentUserId: content.currentUserId
        )
        threadTitleLabel.text = channelName
        threadDescriptionLabel.text = "replied to: \(thread.parentMessage?.text ?? "")"
        replyDescriptionLabel.text = latestReply?.text
        replyTimestampLabel.text = latestReply.map { appearance.formatters.messageTimestamp.format($0.createdAt) }
        replyAuthorAvatarView.content = latestReply?.author
        replyTitleLabel.text = latestReply?.author.name
        let unreads = thread.reads.first(where: { $0.user.id == content.currentUserId })?.unreadMessagesCount ?? 1
        threadUnreadCountView.content = .init(messages: unreads, mentions: 0) // TODO: Make 2 types of unread counts
        threadUnreadCountView.invalidateIntrinsicContentSize()
    }
}
