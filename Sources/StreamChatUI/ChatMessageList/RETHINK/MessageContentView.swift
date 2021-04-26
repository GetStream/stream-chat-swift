//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A protocol for message content delegate responsible for action handling.
///
/// When custom message content view is created, the protocol that inherits from this one
/// should be created if an action can be taken on the new content view.
public protocol MessageContentViewDelegate: AnyObject {
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
public typealias MessageContentView = _MessageContentView<NoExtraData>

/// A view that displays the message content.
open class _MessageContentView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    /// The current layout options of the view.
    /// When this value is set the subviews are instantiated and laid out just once based on
    /// the received options.
    private var layoutOptions: MessageLayoutOptions!

    // MARK: Content && Actions

    /// The index path of the cell which displays the current content view.
    public var indexPath: IndexPath?

    /// The delegate responsible for action handling.
    public weak var delegate: MessageContentViewDelegate?

    /// The message this view displays.
    open var content: _ChatMessage<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Content views

    /// Shows the bubble around message content.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.bubble`.
    public private(set) var bubbleView: _MessageBubbleView<ExtraData>?

    /// Shows message author avatar.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.author`.
    public private(set) var authorAvatarView: ChatAvatarView?

    /// Shows message text content.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.text`.
    public private(set) var textView: UITextView?

    /// Shows message metadata.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.metadata`.
    public private(set) var metadataView: _ChatMessageMetadataView<ExtraData>?

    /// Shows error indicator.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.error`.
    public private(set) var errorIndicatorView: _ChatMessageErrorIndicator<ExtraData>?

    /// Shows the message quoted by the message this view displays.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.quotedMessage`.
    public private(set) var quotedMessageView: _ChatMessageQuoteView<ExtraData>?

    /// Shows message reactions.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.reactions`.
    public private(set) var reactionsView: _ChatMessageReactionsView<ExtraData>?

    /// Shows the bubble around message reactions.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.reactions`.
    public private(set) var reactionsBubbleView: _ReactionsBubbleView<ExtraData>?

    /// Shows the # of thread replies on the message.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.threadInfo`.
    public private(set) var threadReplyCountButton: UIButton?

    /// Shows the avatar of the user who left the latest thread reply.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.threadInfo`.
    public private(set) var threadAvatarView: ChatAvatarView?

    /// Shows the arrow from message bubble to `threadAvatarView` view.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.threadInfo`.
    public private(set) var threadArrowView: _ThreadArrowView<ExtraData>?

    // MARK: - Containers

    /// Specifies the max possible width of `mainContainer`.
    /// Should be in [0...1] range, where 1 makes the container fill the entire superview's width.
    open var maxContentWidthMultiplier: CGFloat { 0.75 }

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

    /// Makes sure the `layout(options: MessageLayoutOptions)` is called just once.
    /// - Parameter options: The options describing the layout of the content view.
    open func setUpLayoutIfNeeded(options: MessageLayoutOptions) {
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
    open func layout(options: MessageLayoutOptions) {
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
                avatarView.widthAnchor.pin(equalToConstant: 32),
                avatarView.heightAnchor.pin(equalToConstant: 32)
            ]

            mainContainer.addArrangedSubview(avatarView)
        }
        
        if options.contains(.avatarSizePadding) {
            let spacer = UIView().withoutAutoresizingMaskConstraints
            spacer.isHidden = true
            constraintsToActivate += [spacer.widthAnchor.pin(equalToConstant: 32)]
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
                arrowView.widthAnchor.pin(equalToConstant: 16),
                threadAvatarView.widthAnchor.pin(equalToConstant: 16),
                threadInfoContainer!.heightAnchor.pin(equalToConstant: 16)
            ]
        }

        // Metadata
        if options.contains(.metadata) {
            let metadataView = createMetadataView()
            bubbleThreadMetaContainer.addArrangedSubview(metadataView)
        }

        // Error
        if options.contains(.error) {
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
        let placeholder = uiConfig.images.userAvatarPlaceholder1
        if let imageURL = content?.author.imageURL {
            authorAvatarView?.imageView.loadImage(from: imageURL, placeholder: placeholder)
        } else {
            authorAvatarView?.imageView.image = placeholder
        }
        
        // Bubble view
        if content?.type == .ephemeral {
            bubbleView?.backgroundColor = uiConfig.colorPalette.popoverBackground
        } else {
            bubbleView?.backgroundColor = content?.isSentByCurrentUser == true ?
                uiConfig.colorPalette.background2 :
                uiConfig.colorPalette.popoverBackground
        }

        // Metadata
        metadataView?.content = content.map {
            .init(message: $0, isAuthorNameShown: layoutOptions?.contains(.authorName) == true)
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
        delegate?.messageContentViewDidTapOnErrorIndicator(indexPath)
    }

    /// Handles tap on `threadReplyCountButton` and forwards the action to the delegate.
    @objc open func handleTapOnThread() {
        delegate?.messageContentViewDidTapOnThread(indexPath)
    }

    /// Handles tap on `quotedMessageView` and forwards the action to the delegate.
    @objc open func handleTapOnQuotedMessage() {
        delegate?.messageContentViewDidTapOnQuotedMessage(indexPath)
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
            textView?.font = uiConfig.font.body
        }
        return textView!
    }

    /// Instantiates, configures and assigns `authorAvatarView` when called for the first time.
    /// - Returns: The `authorAvatarView` subview.
    open func createAvatarView() -> ChatAvatarView {
        if authorAvatarView == nil {
            authorAvatarView = uiConfig
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
            threadAvatarView = uiConfig
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
    open func createThreadArrowView() -> _ThreadArrowView<ExtraData> {
        if threadArrowView == nil {
            // TODO: view type should be taken from `uiConfig` once `_ThreadArrowView` is audited
            threadArrowView = _ThreadArrowView<ExtraData>()
                .withoutAutoresizingMaskConstraints
        }
        return threadArrowView!
    }

    /// Instantiates, configures and assigns `threadReplyCountButton` when called for the first time.
    /// - Returns: The `threadReplyCountButton` subview.
    open func createThreadReplyCountButton() -> UIButton {
        if threadReplyCountButton == nil {
            threadReplyCountButton = UIButton(type: .custom).withoutAutoresizingMaskConstraints
            threadReplyCountButton!.titleLabel?.font = uiConfig.font.footnoteBold
            threadReplyCountButton!.titleLabel?.adjustsFontForContentSizeCategory = true
            threadReplyCountButton!.addTarget(self, action: #selector(handleTapOnThread), for: .touchUpInside)
        }
        return threadReplyCountButton!
    }

    /// Instantiates, configures and assigns `bubbleView` when called for the first time.
    /// - Returns: The `bubbleView` subview.
    open func createBubbleView() -> _MessageBubbleView<ExtraData> {
        if bubbleView == nil {
            bubbleView = _MessageBubbleView<ExtraData>().withoutAutoresizingMaskConstraints
        }
        return bubbleView!
    }

    /// Instantiates, configures and assigns `metadataView` when called for the first time.
    /// - Returns: The `metadataView` subview.
    open func createMetadataView() -> _ChatMessageMetadataView<ExtraData> {
        if metadataView == nil {
            metadataView = uiConfig
                .messageList
                .messageContentSubviews
                .metadataView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        return metadataView!
    }

    /// Instantiates, configures and assigns `quotedMessageView` when called for the first time.
    /// - Returns: The `quotedMessageView` subview.
    open func createQuotedMessageView() -> _ChatMessageQuoteView<ExtraData> {
        if quotedMessageView == nil {
            quotedMessageView = uiConfig
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
            reactionsView = uiConfig
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
    open func createErrorIndicatorView() -> _ChatMessageErrorIndicator<ExtraData> {
        if errorIndicatorView == nil {
            errorIndicatorView = uiConfig
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
    open func createReactionsBubbleView() -> _ReactionsBubbleView<ExtraData> {
        if reactionsBubbleView == nil {
            // TODO: view type should be taken from `uiConfig` once `_ReactionsBubbleView` is audited
            reactionsBubbleView = _ReactionsBubbleView<ExtraData>()
                .withoutAutoresizingMaskConstraints
        }
        return reactionsBubbleView!
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
