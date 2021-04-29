//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A protocol for message content delegate responsible for action handling.
///
/// When custom message content view is created, the protocol that inherits from this one
/// should be created if an action can be taken on the new content view.
public protocol ChatMessageContentViewDelegate: AnyObject {
    /// Gets called when error indicator is tapped.
    /// - Parameter indexPath: The index path of the cell displaying the content view. Equals to `nil` when
    /// the content view is displayed outside the collection/table view.
    func messageContentViewDidTapOnErrorIndicator(_ indexPath: IndexPath?)

    /// Gets called when thread reply button is tapped.
    /// - Parameter indexPath: The index path of the cell displaying the content view. Equals to `nil` when
    /// the content view is displayed outside the collection/table view.
    func messageContentViewDidTapOnThread(_ indexPath: IndexPath?)

    /// Gets called when quoted message view is tapped.
    /// - Parameter indexPath: The index path of the cell displaying the content view. Equals to `nil` when
    /// the content view is displayed outside the collection/table view.
    func messageContentViewDidTapOnQuotedMessage(_ indexPath: IndexPath?)
}

/// A view that displays the message content.
public typealias ChatMessageContentView = _ChatMessageContentView<NoExtraData>

/// A view that displays the message content.
open class _ChatMessageContentView<ExtraData: ExtraDataTypes>: _View, ThemeProvider {
    /// The current layout options of the view.
    /// When this value is set the subviews are instantiated and laid out just once based on
    /// the received options.
    private var layoutOptions: ChatMessageLayoutOptions!

    // MARK: Content && Actions

    /// The provider of cell index path which displays the current content view.
    public var indexPath: (() -> IndexPath?)?

    /// The delegate responsible for action handling.
    public weak var delegate: ChatMessageContentViewDelegate?

    /// The message this view displays.
    open var content: _ChatMessage<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    /// The date formatter of the `timestampLabel`
    public lazy var dateFormatter: DateFormatter = .makeDefault()

    /// Specifies the max possible width of `mainContainer`.
    /// Should be in [0...1] range, where 1 makes the container fill the entire superview's width.
    open var maxContentWidthMultiplier: CGFloat { 0.75 }

    /// Specifies the size of `authorAvatarView`. In case `.avatarSizePadding` option is set the leading offset
    /// for the content will taken from the provided `width`.
    open var messageAuthorAvatarSize: CGSize { .init(width: 32, height: 32) }

    // MARK: - Content views

    /// Shows the bubble around message content.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.bubble`.
    public private(set) var bubbleView: ChatMessageBubbleView?

    /// Shows message author avatar.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.author`.
    public private(set) var authorAvatarView: ChatAvatarView?

    /// Shows message text content.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.text`.
    public private(set) var textView: UITextView?

    /// Shows message timestamp.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.metadata`.
    public private(set) var timestampLabel: UILabel?

    /// Shows message author name.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.authorName`.
    public private(set) var authorNameLabel: UILabel?

    /// Shows the icon part of the indicator saying the message is visible for current user only.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.metadata`
    /// and `.onlyVisibleForYouIndicator`.
    public private(set) var onlyVisibleForYouIconImageView: UIImageView?

    /// Shows the text part of the indicator saying the message is visible for current user only.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.metadata`
    /// and `.onlyVisibleForYouIndicator`.
    public private(set) var onlyVisibleForYouLabel: UILabel?

    /// Shows error indicator.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.error`.
    public private(set) var errorIndicatorView: ChatMessageErrorIndicator?

    /// Shows the message quoted by the message this view displays.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.quotedMessage`.
    public private(set) var quotedMessageView: _ChatMessageQuoteView<ExtraData>?

    /// Shows message reactions.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.reactions`.
    public private(set) var reactionsView: _ChatMessageReactionsView<ExtraData>?

    /// Shows the bubble around message reactions.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.reactions`.
    public private(set) var reactionsBubbleView: ChatReactionsBubbleView?

    /// Shows the # of thread replies on the message.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.threadInfo`.
    public private(set) var threadReplyCountButton: UIButton?

    /// Shows the avatar of the user who left the latest thread reply.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.threadInfo`.
    public private(set) var threadAvatarView: ChatAvatarView?

    /// Shows the arrow from message bubble to `threadAvatarView` view.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.threadInfo`.
    public private(set) var threadArrowView: ChatThreadArrowView?

    // MARK: - Containers

    /// The root container which holds `authorAvatarView` (or the avatar padding) and `bubbleThreadMetaContainer`.
    public lazy var mainContainer = ContainerStackView(axis: .horizontal)
        .withoutAutoresizingMaskConstraints

    /// The container which holds `bubbleView` (or `bubbleContentContainer` directly), `threadInfoContainer`, and `metadataView`
    public private(set) lazy var bubbleThreadMetaContainer = ContainerStackView(axis: .vertical, spacing: 4)
        .withoutAutoresizingMaskConstraints

    /// The container which holds `quotedMessageView` and `textView`. It will be added as a subview to `bubbleView` if it exists
    /// otherwise it will be added to `bubbleThreadMetaContainer`.
    public private(set) lazy var bubbleContentContainer = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints

    /// The container which holds `threadArrowView`, `threadAvatarView`, and `threadReplyCountButton`
    public private(set) var threadInfoContainer: ContainerStackView?

    /// The container which holds `timestampLabel`, `authorNameLabel`, and `onlyVisibleForYouContainer` if it exists
    public private(set) var metadataContainer: ContainerStackView?

    /// The container which holds `onlyVisibleForYouIconImageView` and `onlyVisibleForYouLabel`
    public private(set) var onlyVisibleForYouContainer: ContainerStackView?

    /// Makes sure the `layout(options: ChatMessageLayoutOptions)` is called just once.
    /// - Parameter options: The options describing the layout of the content view.
    open func setUpLayoutIfNeeded(options: ChatMessageLayoutOptions) {
        guard layoutOptions == nil else {
            log.assert(layoutOptions == options, """
            Attempt to setup "\(options)" layout for \(self) while it has already been laid out with "\(layoutOptions!)" options.
            `MessageContentView` is supposed to be laid out only once.
            """)
            return
        }
        layout(options: options)
        layoutOptions = options
    }

    /// Instantiates the subviews and laid them out based on the received options.
    /// - Parameter options: The options describing the layout of the content view.
    open func layout(options: ChatMessageLayoutOptions) {
        var constraintsToActivate: [NSLayoutConstraint] = []

        // Main container
        mainContainer.alignment = .trailing
        mainContainer.isLayoutMarginsRelativeArrangement = true
        mainContainer.layoutMargins.top = 0

        addSubview(mainContainer)
        constraintsToActivate += [
            mainContainer.bottomAnchor.pin(equalTo: bottomAnchor),
            mainContainer.widthAnchor.pin(
                lessThanOrEqualTo: widthAnchor,
                multiplier: maxContentWidthMultiplier
            )
        ]

        if options.contains(.flipped) {
            constraintsToActivate += [
                mainContainer.trailingAnchor
                    .pin(equalTo: trailingAnchor)
                    .almostRequired
            ]
        } else {
            constraintsToActivate += [
                mainContainer.leadingAnchor
                    .pin(equalTo: leadingAnchor)
                    .almostRequired
            ]
        }

        // Avatar view
        if options.contains(.avatar) {
            let avatarView = createAvatarView()
            constraintsToActivate += [
                avatarView.widthAnchor.pin(equalToConstant: messageAuthorAvatarSize.width),
                avatarView.heightAnchor.pin(equalToConstant: messageAuthorAvatarSize.height)
            ]

            mainContainer.addArrangedSubview(avatarView)
        }

        if options.contains(.avatarSizePadding) {
            let spacer = UIView().withoutAutoresizingMaskConstraints
            spacer.isHidden = true
            constraintsToActivate += [spacer.widthAnchor.pin(equalToConstant: messageAuthorAvatarSize.width)]
            mainContainer.addArrangedSubview(spacer)
        }

        // Bubble - Thread - Metadata
        bubbleThreadMetaContainer.alignment = options.contains(.flipped) ? .trailing : .leading
        mainContainer.addArrangedSubview(bubbleThreadMetaContainer)

        // Bubble view
        if options.contains(.bubble) {
            let bubbleView = createBubbleView()
            bubbleView.embed(bubbleContentContainer)

            if options.contains(.continuousBubble) {
                bubbleView.roundedCorners = .all
                mainContainer.layoutMargins.bottom = 0
            } else if options.contains(.flipped) {
                bubbleView.roundedCorners = CACornerMask.all.subtracting(.layerMaxXMaxYCorner)
            } else {
                bubbleView.roundedCorners = CACornerMask.all.subtracting(.layerMinXMaxYCorner)
            }

            bubbleThreadMetaContainer.addArrangedSubview(bubbleView)
        } else {
            bubbleThreadMetaContainer.addArrangedSubview(bubbleContentContainer)
        }

        // Thread info
        if options.contains(.threadInfo) {
            threadInfoContainer = ContainerStackView()
            bubbleThreadMetaContainer.addArrangedSubview(threadInfoContainer!)

            let arrowView = createThreadArrowView()
            let threadAvatarView = createThreadAvatarView()
            let threadReplyCountButton = createThreadReplyCountButton()

            let arrangedSubviews = [
                arrowView,
                threadAvatarView,
                threadReplyCountButton
            ]

            if options.contains(.flipped) {
                arrowView.direction = .toLeading
                threadInfoContainer!.addArrangedSubviews(arrangedSubviews.reversed())
                threadInfoContainer!.setCustomSpacing(0, after: threadAvatarView)
            } else {
                arrowView.direction = .toTrailing
                threadInfoContainer!.addArrangedSubviews(arrangedSubviews)
                threadInfoContainer!.setCustomSpacing(0, after: arrowView)
            }

            constraintsToActivate += [
                threadInfoContainer!.heightAnchor.pin(equalToConstant: 16),
                arrowView.widthAnchor.pin(equalTo: threadInfoContainer!.heightAnchor),
                threadAvatarView.widthAnchor.pin(equalTo: threadInfoContainer!.heightAnchor)
            ]
        }

        // Metadata
        if options.contains(.metadata) {
            var metadataSubviews: [UIView] = [
                createAuthorNameLabel(),
                createTimestampLabel()
            ]

            if options.contains(.onlyVisibleForYouIndicator) {
                onlyVisibleForYouContainer = ContainerStackView()
                onlyVisibleForYouContainer!.addArrangedSubview(createOnlyVisibleForYouIconImageView())
                onlyVisibleForYouContainer!.addArrangedSubview(createOnlyVisibleForYouLabel())
                metadataSubviews.insert(onlyVisibleForYouContainer!, at: 0)
            }

            metadataContainer = ContainerStackView(arrangedSubviews: metadataSubviews)
            bubbleThreadMetaContainer.addArrangedSubview(metadataContainer!)
        }

        // Error
        if options.contains(.errorIndicator) {
            let errorIndicatorView = createErrorIndicatorView()
            errorIndicatorView.setContentCompressionResistancePriority(.streamRequire, for: .horizontal)
            errorIndicatorView.setContentCompressionResistancePriority(.streamRequire, for: .vertical)
            addSubview(errorIndicatorView)

            constraintsToActivate += [
                errorIndicatorView.bottomAnchor.pin(equalTo: (bubbleView ?? bubbleContentContainer).bottomAnchor),
                errorIndicatorView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
                bubbleThreadMetaContainer.trailingAnchor.pin(equalTo: errorIndicatorView.centerXAnchor)
            ]
        }

        // Quoted message
        if options.contains(.quotedMessage) {
            let quotedMessageView = createQuotedMessageView()
            bubbleContentContainer.addArrangedSubview(quotedMessageView, respectsLayoutMargins: true)
        }

        // Text
        if options.contains(.text) {
            let textView = createTextView()
            bubbleContentContainer.addArrangedSubview(textView, respectsLayoutMargins: true)
        }

        // Reactions
        if options.contains(.reactions) {
            let reactionsBubbleView = createReactionsBubbleView()
            addSubview(reactionsBubbleView)

            let reactionsView = createReactionsView()
            reactionsBubbleView.addSubview(reactionsView)
            reactionsView.pin(to: reactionsBubbleView.layoutMarginsGuide)

            constraintsToActivate += [
                reactionsBubbleView.topAnchor.pin(equalTo: topAnchor),
                (bubbleView ?? bubbleContentContainer).topAnchor.pin(equalTo: reactionsBubbleView.centerYAnchor),
                reactionsBubbleView.centerXAnchor.pin(
                    equalTo: options.contains(.flipped) ?
                        mainContainer.leadingAnchor :
                        mainContainer.trailingAnchor
                )
            ]
        } else {
            constraintsToActivate += [
                mainContainer.topAnchor.pin(equalTo: topAnchor)
            ]
        }

        NSLayoutConstraint.activate(constraintsToActivate)
    }

    override open func updateContent() {
        super.updateContent()

        // Text
        textView?.text = content?.text

        // Avatar
        let placeholder = appearance.images.userAvatarPlaceholder1
        if let imageURL = content?.author.imageURL {
            authorAvatarView?.imageView.loadImage(from: imageURL, placeholder: placeholder)
        } else {
            authorAvatarView?.imageView.image = placeholder
        }

        // Bubble view
        if content?.type == .ephemeral {
            bubbleView?.backgroundColor = appearance.colorPalette.popoverBackground
        } else {
            bubbleView?.backgroundColor = content?.isSentByCurrentUser == true ?
                appearance.colorPalette.background2 :
                appearance.colorPalette.popoverBackground
        }

        // Metadata
        onlyVisibleForYouContainer?.isVisible = content?.onlyVisibleForCurrentUser ?? false

        authorNameLabel?.isVisible = layoutOptions?.contains(.authorName) == true
        authorNameLabel?.text = content?.author.name

        if let createdAt = content?.createdAt {
            timestampLabel?.text = dateFormatter.string(from: createdAt)
        } else {
            timestampLabel?.text = nil
        }

        // Quoted message view
        quotedMessageView?.content = content?.quotedMessage.map {
            .init(message: $0, avatarAlignment: $0.isSentByCurrentUser ? .right : .left)
        }

        // Thread info
        threadReplyCountButton?.setTitleColor(tintColor, for: .normal)
        if let replyCount = content?.replyCount {
            threadReplyCountButton?.setTitle(L10n.Message.Threads.count(replyCount), for: .normal)
        } else {
            threadReplyCountButton?.setTitle(L10n.Message.Threads.reply, for: .normal)
        }
        let latestReplyAuthorAvatar = content?.latestReplies.first?.author.imageURL
        threadAvatarView?.imageView.loadImage(from: latestReplyAuthorAvatar)

        // Reactions view
        reactionsBubbleView?.tailDirection = content
            .map { $0.isSentByCurrentUser ? .toTrailing : .toLeading }
        reactionsView?.content = content.map {
            .init(
                useBigIcons: false,
                reactions: $0.reactions,
                didTapOnReaction: nil
            )
        }
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()

        // We need to update the content and manually apply the updated `tintColor`
        // to the subviews which don't listen for `tintColor` updates.
        updateContentIfNeeded()
    }

    /// Cleans up the view so it is ready to display another message.
    func prepareForReuse() {
        content = nil
        delegate = nil
        indexPath = nil
    }

    // MARK: - Actions

    /// Handles tap on `errorIndicatorView` and forwards the action to the delegate.
    @objc open func handleTapOnErrorIndicator() {
        delegate?.messageContentViewDidTapOnErrorIndicator(indexPath?())
    }

    /// Handles tap on `threadReplyCountButton` and forwards the action to the delegate.
    @objc open func handleTapOnThread() {
        delegate?.messageContentViewDidTapOnThread(indexPath?())
    }

    /// Handles tap on `quotedMessageView` and forwards the action to the delegate.
    @objc open func handleTapOnQuotedMessage() {
        delegate?.messageContentViewDidTapOnQuotedMessage(indexPath?())
    }

    // MARK: - Setups

    /// Instantiates, configures and assigns `textView` when called for the first time.
    /// - Returns: The `textView` subview.
    open func createTextView() -> UITextView {
        if textView == nil {
            textView = OnlyLinkTappableTextView().withoutAutoresizingMaskConstraints
            textView?.isEditable = false
            textView?.dataDetectorTypes = .link
            textView?.isScrollEnabled = false
            textView?.backgroundColor = .clear
            textView?.adjustsFontForContentSizeCategory = true
            textView?.textContainerInset = .init(top: 0, left: 8, bottom: 0, right: 8)
            textView?.textContainer.lineFragmentPadding = 0
            textView?.translatesAutoresizingMaskIntoConstraints = false
            textView?.font = appearance.fonts.body
        }
        return textView!
    }

    /// Instantiates, configures and assigns `authorAvatarView` when called for the first time.
    /// - Returns: The `authorAvatarView` subview.
    open func createAvatarView() -> ChatAvatarView {
        if authorAvatarView == nil {
            authorAvatarView = components
                .messageList
                .messageContentSubviews
                .authorAvatarView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        return authorAvatarView!
    }

    /// Instantiates, configures and assigns `threadAvatarView` when called for the first time.
    /// - Returns: The `threadAvatarView` subview.
    open func createThreadAvatarView() -> ChatAvatarView {
        if threadAvatarView == nil {
            threadAvatarView = components
                .messageList
                .messageContentSubviews
                .authorAvatarView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        return threadAvatarView!
    }

    /// Instantiates, configures and assigns `threadArrowView` when called for the first time.
    /// - Returns: The `threadArrowView` subview.
    open func createThreadArrowView() -> ChatThreadArrowView {
        if threadArrowView == nil {
            // TODO: view type should be taken from `components` once `_ThreadArrowView` is audited
            threadArrowView = ChatThreadArrowView()
                .withoutAutoresizingMaskConstraints
        }
        return threadArrowView!
    }

    /// Instantiates, configures and assigns `threadReplyCountButton` when called for the first time.
    /// - Returns: The `threadReplyCountButton` subview.
    open func createThreadReplyCountButton() -> UIButton {
        if threadReplyCountButton == nil {
            threadReplyCountButton = UIButton(type: .custom).withoutAutoresizingMaskConstraints
            threadReplyCountButton!.titleLabel?.font = appearance.fonts.footnoteBold
            threadReplyCountButton!.titleLabel?.adjustsFontForContentSizeCategory = true
            threadReplyCountButton!.addTarget(self, action: #selector(handleTapOnThread), for: .touchUpInside)
        }
        return threadReplyCountButton!
    }

    /// Instantiates, configures and assigns `bubbleView` when called for the first time.
    /// - Returns: The `bubbleView` subview.
    open func createBubbleView() -> ChatMessageBubbleView {
        if bubbleView == nil {
            bubbleView = ChatMessageBubbleView().withoutAutoresizingMaskConstraints
        }
        return bubbleView!
    }

    /// Instantiates, configures and assigns `quotedMessageView` when called for the first time.
    /// - Returns: The `quotedMessageView` subview.
    open func createQuotedMessageView() -> _ChatMessageQuoteView<ExtraData> {
        if quotedMessageView == nil {
            quotedMessageView = components
                .messageQuoteView
                .init()
                .withoutAutoresizingMaskConstraints

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapOnQuotedMessage))
            quotedMessageView!.addGestureRecognizer(tapRecognizer)
        }
        return quotedMessageView!
    }

    /// Instantiates, configures and assigns `reactionsView` when called for the first time.
    /// - Returns: The `reactionsView` subview.
    open func createReactionsView() -> _ChatMessageReactionsView<ExtraData> {
        if reactionsView == nil {
            reactionsView = components
                .messageList
                .messageReactions
                .reactionsView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        return reactionsView!
    }

    /// Instantiates, configures and assigns `errorIndicatorView` when called for the first time.
    /// - Returns: The `errorIndicatorView` subview.
    open func createErrorIndicatorView() -> ChatMessageErrorIndicator {
        if errorIndicatorView == nil {
            errorIndicatorView = components
                .messageList
                .messageContentSubviews
                .errorIndicator
                .init()
                .withoutAutoresizingMaskConstraints

            errorIndicatorView!.addTarget(self, action: #selector(handleTapOnErrorIndicator), for: .touchUpInside)
        }
        return errorIndicatorView!
    }

    /// Instantiates, configures and assigns `reactionsBubbleView` when called for the first time.
    /// - Returns: The `reactionsBubbleView` subview.
    open func createReactionsBubbleView() -> ChatReactionsBubbleView {
        if reactionsBubbleView == nil {
            // TODO: view type should be taken from `components` once `_ReactionsBubbleView` is audited
            reactionsBubbleView = ChatReactionsBubbleView()
                .withoutAutoresizingMaskConstraints
        }
        return reactionsBubbleView!
    }

    /// Instantiates, configures and assigns `timestampLabel` when called for the first time.
    /// - Returns: The `timestampLabel` subview.
    open func createTimestampLabel() -> UILabel {
        if timestampLabel == nil {
            timestampLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints

            timestampLabel!.textColor = appearance.colorPalette.subtitleText
            timestampLabel!.font = appearance.fonts.footnote
        }
        return timestampLabel!
    }

    /// Instantiates, configures and assigns `authorNameLabel` when called for the first time.
    /// - Returns: The `authorNameLabel` subview.
    open func createAuthorNameLabel() -> UILabel {
        if authorNameLabel == nil {
            authorNameLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints
        }
        return authorNameLabel!
    }

    /// Instantiates, configures and assigns `onlyVisibleForYouIconImageView` when called for the first time.
    /// - Returns: The `onlyVisibleForYouIconImageView` subview.
    open func createOnlyVisibleForYouIconImageView() -> UIImageView {
        if onlyVisibleForYouIconImageView == nil {
            onlyVisibleForYouIconImageView = UIImageView()
                .withoutAutoresizingMaskConstraints

            onlyVisibleForYouIconImageView!.tintColor = appearance.colorPalette.subtitleText
            onlyVisibleForYouIconImageView!.image = appearance.images.onlyVisibleToCurrentUser
            onlyVisibleForYouIconImageView!.contentMode = .scaleAspectFit
        }
        return onlyVisibleForYouIconImageView!
    }

    /// Instantiates, configures and assigns `onlyVisibleForYouLabel` when called for the first time.
    /// - Returns: The `onlyVisibleForYouLabel` subview.
    open func createOnlyVisibleForYouLabel() -> UILabel {
        if onlyVisibleForYouLabel == nil {
            onlyVisibleForYouLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints

            onlyVisibleForYouLabel!.textColor = appearance.colorPalette.subtitleText
            onlyVisibleForYouLabel!.text = L10n.Message.onlyVisibleToYou
            onlyVisibleForYouLabel!.font = appearance.fonts.footnote
        }
        return onlyVisibleForYouLabel!
    }
}

private extension _ChatMessage {
    var reactions: [ChatMessageReactionData] {
        let userReactionIDs = Set(currentUserReactions.map(\.type))
        return reactionScores
            .keys
            .sorted { $0.rawValue < $1.rawValue }
            .map { .init(type: $0, isChosenByCurrentUser: userReactionIDs.contains($0)) }
    }
}
