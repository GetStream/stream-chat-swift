//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
	
    /// Gets called when avatar view is tapped.
    /// - Parameter indexPath: The index path of the cell displaying the content view. Equals to `nil` when
    /// the content view is displayed outside the collection/table view.
    func messageContentViewDidTapOnAvatarView(_ indexPath: IndexPath?)

    /// Gets called when reactions view is tapped.
    /// - Parameter indexPath: The index path of the cell displaying the content view. Equals to `nil` when
    /// the content view is displayed outside the collection/table view.
    func messageContentViewDidTapOnReactionsView(_ indexPath: IndexPath?)
    
    /// Gets called when delivery status indicator is tapped.
    /// - Parameter indexPath: The index path of the cell displaying the content view. Equals to `nil` when
    /// the content view is displayed outside the collection/table view.
    func messageContentViewDidTapOnDeliveryStatusIndicator(_ indexPath: IndexPath?)
}

public extension ChatMessageContentViewDelegate {
    func messageContentViewDidTapOnDeliveryStatusIndicator(_ indexPath: IndexPath?) {}
}

/// A view that displays the message content.
open class ChatMessageContentView: _View, ThemeProvider {
    /// The current layout options of the view.
    /// When this value is set the subviews are instantiated and laid out just once based on
    /// the received options.
    public var layoutOptions: ChatMessageLayoutOptions?
    
    /// The formatter used for text Markdown
    public var markdownFormatter: MarkdownFormatter {
        appearance.formatters.markdownFormatter
    }
    
    /// A boolean value that determines whether Markdown is active for messages to be formatted.
    open var markdownFormatterEnabled: Bool {
        appearance.formatters.markdownFormatterEnabled
    }

    // MARK: Content && Actions

    /// The provider of cell index path which displays the current content view.
    public var indexPath: (() -> IndexPath?)?

    /// The delegate responsible for action handling.
    public weak var delegate: ChatMessageContentViewDelegate?

    // TODO: Aggregate message and channel under one `struct Content` roof in v5
    /// The message this view displays.
    open var content: ChatMessage? {
        didSet { updateContentIfNeeded() }
    }
    
    /// The channel the message is sent to.
    open var channel: ChatChannel? {
        didSet { updateContentIfNeeded() }
    }

    /// A formatter that converts the message timestamp to textual representation.
    public lazy var timestampFormatter: MessageTimestampFormatter = appearance.formatters.messageTimestamp

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

    /// Shows a spacer where the author avatar should be.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.avatarSizePadding`.
    public private(set) var authorAvatarSpacer: UIView?

    /// Shows message text content.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.text`.
    public private(set) var textView: UITextView?

    /// Shows message timestamp.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.timestamp`.
    public private(set) var timestampLabel: UILabel?

    /// Shows message author name.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.authorName`.
    public private(set) var authorNameLabel: UILabel?

    /// Shows the icon part of the indicator saying the message is visible for current user only.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options
    /// containing `.onlyVisibleToYouIndicator`.
    public private(set) var onlyVisibleToYouImageView: UIImageView?

    /// Shows the text part of the indicator saying the message is visible for current user only.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options
    /// containing `.onlyVisibleToYouIndicator`
    public private(set) var onlyVisibleToYouLabel: UILabel?

    /// Shows error indicator.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.errorIndicator`.
    public private(set) var errorIndicatorView: ChatMessageErrorIndicator?

    /// Shows the message quoted by the message this view displays.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.quotedMessage`.
    public private(set) var quotedMessageView: QuotedChatMessageView?

    /// Shows message reactions.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.reactions`.
    public private(set) var reactionsView: ChatMessageReactionsView?

    /// Shows the bubble around message reactions.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.reactions`.
    public private(set) var reactionsBubbleView: ChatReactionBubbleBaseView?

    /// Shows the # of thread replies on the message.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.threadInfo`.
    public private(set) var threadReplyCountButton: UIButton?

    /// Shows the avatar of the user who left the latest thread reply.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.threadInfo`.
    public private(set) var threadAvatarView: ChatAvatarView?

    /// Shows the arrow from message bubble to `threadAvatarView` view.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.threadInfo`.
    public private(set) var threadArrowView: ChatThreadArrowView?

    /// Shows message delivery status.
    /// Exists if `layout(options: ChatMessageLayoutOption)` was invoked with the options
    /// containing `.messageDeliveryStatus`.
    public private(set) var deliveryStatusView: ChatMessageDeliveryStatusView?
    
    /// An object responsible for injecting the views needed to display the attachments content.
    public private(set) var attachmentViewInjector: AttachmentViewInjector?

    // MARK: - Containers

    /// The root container which holds `authorAvatarView` (or the avatar padding) and `bubbleThreadMetaContainer`.
    public lazy var mainContainer = ContainerStackView(axis: .horizontal)
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "mainContainer")

    /// The container which holds `bubbleView` (or `bubbleContentContainer` directly), `threadInfoContainer`, and `footnoteContainer`
    public private(set) lazy var bubbleThreadFootnoteContainer = ContainerStackView(axis: .vertical, spacing: 4)
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "bubbleThreadFootnoteContainer")

    /// The container which holds `quotedMessageView` and `textView`. It will be added as a subview to `bubbleView` if it exists
    /// otherwise it will be added to `bubbleThreadMetaContainer`.
    public private(set) lazy var bubbleContentContainer = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "bubbleContentContainer")

    /// The container which holds `threadArrowView`, `threadAvatarView`, and `threadReplyCountButton`
    public private(set) var threadInfoContainer: ContainerStackView?

    /// The container which holds `timestampLabel`, `authorNameLabel`, and `onlyVisibleToYouContainer`.
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with any of
    /// `.timestamp/.authorName/.onlyVisibleToYouIndicator` options
    public private(set) var footnoteContainer: ContainerStackView?

    /// The container which holds `onlyVisibleToYouImageView` and `onlyVisibleToYouLabel`
    public private(set) var onlyVisibleToYouContainer: ContainerStackView?

    /// The container which holds `errorIndicatorView`
    /// Exists if `layout(options: MessageLayoutOptions)` was invoked with the options containing `.errorIndicator`.
    public private(set) var errorIndicatorContainer: UIView?

    /// Constraint between bubble and reactions.
    public private(set) var bubbleToReactionsConstraint: NSLayoutConstraint?
    
    /// Makes sure the `layout(options: ChatMessageLayoutOptions)` is called just once.
    /// - Parameter options: The options describing the layout of the content view.
    open func setUpLayoutIfNeeded(
        options: ChatMessageLayoutOptions,
        attachmentViewInjectorType: AttachmentViewInjector.Type?
    ) {
        guard layoutOptions == nil else {
            log.assert(layoutOptions == options, """
            Attempt to setup "\(options)" layout for \(self) while it has already been laid out with "\(layoutOptions!)" options.
            `MessageContentView` is supposed to be laid out only once.
            """)
            return
        }

        attachmentViewInjector = attachmentViewInjectorType?.init(self)
        layoutOptions = options
    }
    
    // swiftlint:disable function_body_length

    /// Instantiates the subviews and laid them out based on the received options.
    /// - Parameter options: The options describing the layout of the content view.
    open func layout(options: ChatMessageLayoutOptions) {
        defer {
            attachmentViewInjector?.contentViewDidLayout(options: options)
        }

        var constraintsToActivate: [NSLayoutConstraint] = []

        // Avatar view
        if options.contains(.avatar) {
            let avatarView = createAvatarView()
            constraintsToActivate += [
                avatarView.widthAnchor.pin(equalToConstant: messageAuthorAvatarSize.width),
                avatarView.heightAnchor.pin(equalToConstant: messageAuthorAvatarSize.height)
            ]
        }

        // Avatar spacer
        if options.contains(.avatarSizePadding) {
            let avatarSpacer = createAvatarSpacer()
            constraintsToActivate += [
                avatarSpacer.widthAnchor.pin(equalToConstant: messageAuthorAvatarSize.width)
            ]
        }

        // Bubble - Thread - Metadata
        bubbleThreadFootnoteContainer.alignment = attachmentViewInjector?.fillAllAvailableWidth == true
            ? .fill
            : options.contains(.flipped) ? .trailing : .leading

        // Bubble view
        if options.contains(.bubble) {
            let bubbleView = createBubbleView()
            bubbleView.embed(bubbleContentContainer)

            if options.contains(.continuousBubble) && !options.contains(.threadInfo) {
                mainContainer.layoutMargins.bottom = 0
            }

            bubbleThreadFootnoteContainer.addArrangedSubview(bubbleView)
        } else {
            bubbleThreadFootnoteContainer.addArrangedSubview(bubbleContentContainer)
        }

        // Thread info
        if options.contains(.threadInfo) {
            threadInfoContainer = ContainerStackView().withAccessibilityIdentifier(identifier: "threadInfoContainer")
            bubbleThreadFootnoteContainer.addArrangedSubview(threadInfoContainer!)

            let arrowView = createThreadArrowView()
            let threadAvatarView = createThreadAvatarView()
            let threadReplyCountButton = createThreadReplyCountButton()

            var arrangedSubviews = [
                arrowView,
                threadAvatarView,
                threadReplyCountButton
            ]
            
            if attachmentViewInjector?.fillAllAvailableWidth == true {
                arrangedSubviews.append(.spacer(axis: .horizontal))
            }

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
        if options.hasFootnoteOptions {
            var footnoteSubviews: [UIView] = []
            
            if options.contains(.authorName) {
                footnoteSubviews.append(createAuthorNameLabel())
            }
            if options.contains(.timestamp) {
                footnoteSubviews.append(createTimestampLabel())
            }
            if options.contains(.onlyVisibleToYouIndicator) {
                onlyVisibleToYouContainer = ContainerStackView()
                    .withAccessibilityIdentifier(identifier: "onlyVisibleToYouContainer")
                onlyVisibleToYouContainer!.addArrangedSubview(createOnlyVisibleToYouImageView())
                onlyVisibleToYouContainer!.addArrangedSubview(createOnlyVisibleToYouLabel())
                footnoteSubviews.append(onlyVisibleToYouContainer!)
            }
            if options.contains(.deliveryStatusIndicator) {
                footnoteSubviews.append(createDeliveryStatusView())
            }
            if attachmentViewInjector?.fillAllAvailableWidth == true {
                footnoteSubviews.append(.spacer(axis: .horizontal))
            }
            
            footnoteContainer = ContainerStackView(
                spacing: 4,
                arrangedSubviews: options.contains(.flipped) ? footnoteSubviews.reversed() : footnoteSubviews
            ).withAccessibilityIdentifier(identifier: "footnoteContainer")
            bubbleThreadFootnoteContainer.addArrangedSubview(footnoteContainer!)
        }

        // Error
        if options.contains(.errorIndicator) {
            let errorIndicatorView = createErrorIndicatorView()
            errorIndicatorView.setContentCompressionResistancePriority(.streamRequire, for: .horizontal)
            errorIndicatorView.setContentCompressionResistancePriority(.streamRequire, for: .vertical)

            let errorIndicatorContainer = createErrorIndicatorContainer()
            errorIndicatorContainer.addSubview(errorIndicatorView)

            constraintsToActivate += [
                errorIndicatorView.leadingAnchor.pin(equalTo: errorIndicatorContainer.leadingAnchor),
                errorIndicatorView.trailingAnchor.pin(equalTo: errorIndicatorContainer.trailingAnchor),
                errorIndicatorView.topAnchor.pin(equalTo: errorIndicatorContainer.topAnchor),
                errorIndicatorView.bottomAnchor.pin(equalTo: (bubbleView ?? bubbleContentContainer).bottomAnchor)
            ]
        }

        // Quoted message
        if options.contains(.quotedMessage) {
            let quotedMessageView = createQuotedMessageView()
            bubbleContentContainer.addArrangedSubview(quotedMessageView)
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

            bubbleToReactionsConstraint = (bubbleView ?? bubbleContentContainer).topAnchor
                .pin(equalTo: reactionsBubbleView.centerYAnchor, constant: 5)
            constraintsToActivate += [
                reactionsBubbleView.topAnchor.pin(equalTo: topAnchor),
                bubbleToReactionsConstraint,
                reactionsBubbleView.centerXAnchor.pin(
                    equalTo: options.contains(.flipped) ?
                        (bubbleView ?? bubbleContentContainer).leadingAnchor :
                        (bubbleView ?? bubbleContentContainer).trailingAnchor,
                    constant: options.contains(.flipped) ? -8 : 8
                )
            ]
            .compactMap { $0 }
        } else {
            constraintsToActivate += [
                mainContainer.topAnchor.pin(equalTo: topAnchor)
            ]
        }

        // Main container

        mainContainer.alignment = .bottom
        mainContainer.isLayoutMarginsRelativeArrangement = true
        mainContainer.layoutMargins.top = 0
        insertSubview(mainContainer, at: 0)

        let mainContainerSubviews = [
            authorAvatarView ?? authorAvatarSpacer,
            errorIndicatorContainer,
            bubbleThreadFootnoteContainer
        ].compactMap { $0 }

        if options.contains(.centered) {
            mainContainer.addArrangedSubviews([bubbleThreadFootnoteContainer])
            
            constraintsToActivate += [
                mainContainer.centerXAnchor
                    .pin(equalTo: centerXAnchor)
            ]
        } else if options.contains(.flipped) {
            mainContainer.addArrangedSubviews(mainContainerSubviews.reversed())

            if let errorIndicator = errorIndicatorView {
                mainContainer.setCustomSpacing(
                    .init(-errorIndicator.intrinsicContentSize.width / 2),
                    after: bubbleThreadFootnoteContainer
                )
            }

            constraintsToActivate += [
                mainContainer.trailingAnchor
                    .pin(equalTo: trailingAnchor)
                    .almostRequired
            ]
        } else {
            mainContainer.addArrangedSubviews(mainContainerSubviews)

            if let errorIndicator = errorIndicatorView {
                mainContainer.setCustomSpacing(
                    .init(-errorIndicator.intrinsicContentSize.width / 2),
                    after: errorIndicatorContainer!
                )
            }

            constraintsToActivate += [
                mainContainer.leadingAnchor
                    .pin(equalTo: leadingAnchor)
            ]
        }

        constraintsToActivate += [
            mainContainer.bottomAnchor.pin(equalTo: bottomAnchor),
            attachmentViewInjector?.fillAllAvailableWidth == true
                ? mainContainer.widthAnchor.pin(
                    equalTo: widthAnchor,
                    multiplier: maxContentWidthMultiplier
                )
                : mainContainer.widthAnchor.pin(
                    lessThanOrEqualTo: widthAnchor,
                    multiplier: maxContentWidthMultiplier
                )
        ]

        NSLayoutConstraint.activate(constraintsToActivate)
    }
    
    // swiftlint:enable function_body_length

    // When the content is updated, we want to make sure there
    // are no unwanted animations caused by the ContainerStackView.
    func updateContentIfNeeded() {
        if superview != nil {
            UIView.performWithoutAnimation {
                updateContent()
            }
        }
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        guard let options = layoutOptions else {
            log.assertionFailure("Layout options are missing")
            return
        }

        layout(options: options)
    }

    override open func updateContent() {
        super.updateContent()
        defer {
            attachmentViewInjector?.contentViewDidUpdateContent()
            setNeedsLayout()
        }

        // Text
        if markdownFormatterEnabled, markdownFormatter.containsMarkdown(content?.textContent ?? "") {
            let markdownText = markdownFormatter.format(content?.textContent ?? "")
            textView?.attributedText = markdownText
        } else {
            var textColor = appearance.colorPalette.text
            var textFont = appearance.fonts.body
            
            if content?.isDeleted == true {
                textColor = appearance.colorPalette.textLowEmphasis
            } else if content?.shouldRenderAsJumbomoji == true {
                textFont = appearance.fonts.emoji
            } else if content?.type == .system || content?.type == .error {
                textFont = appearance.fonts.caption1.bold
                textColor = appearance.colorPalette.textLowEmphasis
            }
            
            textView?.textColor = textColor
            textView?.font = textFont
            textView?.text = content?.textContent
        }
        
        // Avatar
        let placeholder = appearance.images.userAvatarPlaceholder1
        if let imageURL = content?.author.imageURL, let imageView = authorAvatarView?.imageView {
            components.imageLoader.loadImage(
                into: imageView,
                url: imageURL,
                imageCDN: components.imageCDN,
                placeholder: placeholder,
                preferredSize: .avatarThumbnailSize
            )
        } else {
            authorAvatarView?.imageView.image = placeholder
        }

        // Bubble view
        bubbleView?.content = content.map { message in
            var backgroundColor: UIColor {
                if message.isSentByCurrentUser {
                    if message.type == .ephemeral {
                        return appearance.colorPalette.background8
                    } else {
                        return appearance.colorPalette.background6
                    }
                } else {
                    return appearance.colorPalette.background8
                }
            }
            
            return .init(
                backgroundColor: backgroundColor,
                roundedCorners: layoutOptions?.roundedCorners ?? .all
            )
        }

        // Metadata
        onlyVisibleToYouContainer?.isVisible = layoutOptions?.contains(.onlyVisibleToYouIndicator) == true

        authorNameLabel?.isVisible = layoutOptions?.contains(.authorName) == true
        authorNameLabel?.text = content?.author.name

        if let createdAt = content?.createdAt {
            timestampLabel?.text = timestampFormatter.format(createdAt)
        } else {
            timestampLabel?.text = nil
        }

        // Quoted message view
        quotedMessageView?.content = content?.quotedMessage.map {
            .init(message: $0, avatarAlignment: $0.isSentByCurrentUser ? .trailing : .leading)
        }

        // Thread info
        threadReplyCountButton?.setTitleColor(tintColor, for: .normal)
        if let replyCount = content?.replyCount, replyCount > 0 {
            threadReplyCountButton?.setTitle(L10n.Message.Threads.count(replyCount), for: .normal)
        } else {
            threadReplyCountButton?.setTitle(L10n.Message.Threads.reply, for: .normal)
        }

        // The last thread participant is the author of the most recent reply.
        let threadAvatarUrl = content?.threadParticipants.last?.imageURL

        if let imageView = threadAvatarView?.imageView {
            components.imageLoader.loadImage(
                into: imageView,
                url: threadAvatarUrl,
                imageCDN: components.imageCDN,
                placeholder: appearance.images.userAvatarPlaceholder4,
                preferredSize: .avatarThumbnailSize
            )
        }

        // Reactions view
        reactionsBubbleView?.tailDirection = content
            .map { $0.isSentByCurrentUser ? .toTrailing : .toLeading }
        reactionsView?.content = content.map {
            .init(
                useBigIcons: false,
                reactions: $0.reactionsData,
                didTapOnReaction: nil
            )
        }
        
        // Delivery status
        deliveryStatusView?.content = {
            guard let channel = channel, let message = content else { return nil }
            return .init(message: message, channel: channel)
        }()
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()

        // We need to update the content and manually apply the updated `tintColor`
        // to the subviews which don't listen for `tintColor` updates.
        updateContentIfNeeded()
    }

    /// Cleans up the view so it is ready to display another message.
    /// We don't need to reset `content` because all subviews are always updated.
    func prepareForReuse() {
        defer { attachmentViewInjector?.contentViewDidPrepareForReuse() }

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

    /// Handles tap on `avatarView` and forwards the action to the delegate.
    @objc open func handleTapOnAvatarView() {
        delegate?.messageContentViewDidTapOnAvatarView(indexPath?())
    }

    @objc open func handleTapOnReactionsView() {
        delegate?.messageContentViewDidTapOnReactionsView(indexPath?())
    }
    
    /// Handles tap on `deliveryStatusView` and forwards the action to the delegate.
    @objc open func handleTapOnDeliveryStatusView() {
        delegate?.messageContentViewDidTapOnDeliveryStatusIndicator(indexPath?())
    }
	
    // MARK: - Setups

    /// Instantiates, configures and assigns `textView` when called for the first time.
    /// - Returns: The `textView` subview.
    open func createTextView() -> UITextView {
        if textView == nil {
            textView = OnlyLinkTappableTextView()
                .withoutAutoresizingMaskConstraints
                .withAccessibilityIdentifier(identifier: "textView")
            textView?.isEditable = false
            textView?.dataDetectorTypes = .link
            textView?.isScrollEnabled = false
            textView?.backgroundColor = .clear
            textView?.adjustsFontForContentSizeCategory = true
            textView?.textContainerInset = .init(top: 0, left: 8, bottom: 0, right: 8)
            textView?.textContainer.lineFragmentPadding = 0
            textView?.font = appearance.fonts.body
        }
        return textView!
    }

    /// Instantiates, configures and assigns `authorAvatarView` when called for the first time.
    /// - Returns: The `authorAvatarView` subview.
    open func createAvatarView() -> ChatAvatarView {
        if authorAvatarView == nil {
            authorAvatarView = components
                .avatarView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        authorAvatarView?.addTarget(self, action: #selector(handleTapOnAvatarView), for: .touchUpInside)
        return authorAvatarView!
    }

    /// Instantiates, configures and assigns `createAvatarSpacer` when called for the first time.
    /// - Returns: The `authorAvatarSpacer` subview.
    open func createAvatarSpacer() -> UIView {
        if authorAvatarSpacer == nil {
            authorAvatarSpacer = UIView()
                .withoutAutoresizingMaskConstraints
                .withAccessibilityIdentifier(identifier: "authorAvatarSpacer")
        }
        return authorAvatarSpacer!
    }

    /// Instantiates, configures and assigns `threadAvatarView` when called for the first time.
    /// - Returns: The `threadAvatarView` subview.
    open func createThreadAvatarView() -> ChatAvatarView {
        if threadAvatarView == nil {
            threadAvatarView = components
                .avatarView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        return threadAvatarView!
    }

    /// Instantiates, configures and assigns `threadArrowView` when called for the first time.
    /// - Returns: The `threadArrowView` subview.
    open func createThreadArrowView() -> ChatThreadArrowView {
        if threadArrowView == nil {
            // TODO: view type should be taken from `components` once `ThreadArrowView` is audited
            threadArrowView = ChatThreadArrowView()
                .withoutAutoresizingMaskConstraints
        }
        return threadArrowView!
    }

    /// Instantiates, configures and assigns `threadReplyCountButton` when called for the first time.
    /// - Returns: The `threadReplyCountButton` subview.
    open func createThreadReplyCountButton() -> UIButton {
        if threadReplyCountButton == nil {
            threadReplyCountButton = UIButton(type: .custom)
                .withoutAutoresizingMaskConstraints
                .withAccessibilityIdentifier(identifier: "threadReplyCountButton")
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
            bubbleView = components
                .messageBubbleView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        return bubbleView!
    }

    /// Instantiates, configures and assigns `quotedMessageView` when called for the first time.
    /// - Returns: The `quotedMessageView` subview.
    open func createQuotedMessageView() -> QuotedChatMessageView {
        if quotedMessageView == nil {
            quotedMessageView = components
                .quotedMessageView
                .init()
                .withoutAutoresizingMaskConstraints

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapOnQuotedMessage))
            quotedMessageView!.addGestureRecognizer(tapRecognizer)
        }
        return quotedMessageView!
    }

    /// Instantiates, configures and assigns `reactionsView` when called for the first time.
    /// - Returns: The `reactionsView` subview.
    open func createReactionsView() -> ChatMessageReactionsView {
        if reactionsView == nil {
            reactionsView = components
                .messageReactionsView
                .init()
                .withoutAutoresizingMaskConstraints

            let tapRecognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(handleTapOnReactionsView)
            )
            reactionsBubbleView?.addGestureRecognizer(tapRecognizer)
        }
        return reactionsView!
    }

    /// Instantiates, configures and assigns `errorIndicatorView` when called for the first time.
    /// - Returns: The `errorIndicatorView` subview.
    open func createErrorIndicatorView() -> ChatMessageErrorIndicator {
        if errorIndicatorView == nil {
            errorIndicatorView = components
                .messageErrorIndicator
                .init()
                .withoutAutoresizingMaskConstraints

            errorIndicatorView!.addTarget(self, action: #selector(handleTapOnErrorIndicator), for: .touchUpInside)
        }
        return errorIndicatorView!
    }

    /// Instantiates, configures and assigns `errorIndicatorContainer` when called for the first time.
    /// - Returns: The `errorIndicatorContainer` subview.
    open func createErrorIndicatorContainer() -> UIView {
        if errorIndicatorContainer == nil {
            errorIndicatorContainer = UIView()
                .withoutAutoresizingMaskConstraints
                .withAccessibilityIdentifier(identifier: "errorIndicatorContainer")
            errorIndicatorContainer!.layer.zPosition = 1
        }
        return errorIndicatorContainer!
    }

    /// Instantiates, configures and assigns `reactionsBubbleView` when called for the first time.
    /// - Returns: The `reactionsBubbleView` subview.
    open func createReactionsBubbleView() -> ChatReactionBubbleBaseView {
        if reactionsBubbleView == nil {
            reactionsBubbleView = components.messageReactionsBubbleView.init().withoutAutoresizingMaskConstraints
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
                .withAccessibilityIdentifier(identifier: "timestampLabel")

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
                .withAccessibilityIdentifier(identifier: "authorNameLabel")

            authorNameLabel!.textColor = appearance.colorPalette.subtitleText
            authorNameLabel!.font = appearance.fonts.footnote
        }
        return authorNameLabel!
    }

    /// Instantiates, configures and assigns `onlyVisibleToYouImageView` when called for the first time.
    /// - Returns: The `onlyVisibleToYouImageView` subview.
    open func createOnlyVisibleToYouImageView() -> UIImageView {
        if onlyVisibleToYouImageView == nil {
            onlyVisibleToYouImageView = UIImageView()
                .withoutAutoresizingMaskConstraints
                .withAccessibilityIdentifier(identifier: "onlyVisibleToYouImageView")
            onlyVisibleToYouImageView!.tintColor = appearance.colorPalette.subtitleText
            onlyVisibleToYouImageView!.image = appearance.images.onlyVisibleToCurrentUser
            onlyVisibleToYouImageView!.contentMode = .scaleAspectFit
        }
        return onlyVisibleToYouImageView!
    }

    /// Instantiates, configures and assigns `onlyVisibleToYouLabel` when called for the first time.
    /// - Returns: The `onlyVisibleToYouLabel` subview.
    open func createOnlyVisibleToYouLabel() -> UILabel {
        if onlyVisibleToYouLabel == nil {
            onlyVisibleToYouLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints
                .withAccessibilityIdentifier(identifier: "onlyVisibleToYouLabel")

            onlyVisibleToYouLabel!.textColor = appearance.colorPalette.subtitleText
            onlyVisibleToYouLabel!.text = L10n.Message.onlyVisibleToYou
            onlyVisibleToYouLabel!.font = appearance.fonts.footnote
        }
        return onlyVisibleToYouLabel!
    }
    
    /// Instantiates, configures and assigns `deliveryStatusView` when called for the first time.
    /// - Returns: The `deliveryStatusView` subview.
    open func createDeliveryStatusView() -> ChatMessageDeliveryStatusView {
        if deliveryStatusView == nil {
            deliveryStatusView = components
                .messageDeliveryStatusView
                .init()
                .withAccessibilityIdentifier(identifier: "deliveryStatusView")
            
            deliveryStatusView!.addTarget(self, action: #selector(handleTapOnDeliveryStatusView), for: .touchUpInside)
        }
        return deliveryStatusView!
    }
}

private extension ChatMessage {
    var reactionsData: [ChatMessageReactionData] {
        let userReactionIDs = Set(currentUserReactions.map(\.type))
        return reactionScores
            .map { ChatMessageReactionData(
                type: $0.key,
                score: $0.value,
                isChosenByCurrentUser: userReactionIDs.contains($0.key)
            ) }
    }
}

private extension ChatMessageLayoutOptions {
    static let footnote: Self = [
        .onlyVisibleToYouIndicator,
        .authorName,
        .timestamp,
        .deliveryStatusIndicator
    ]
    
    var hasFootnoteOptions: Bool {
        !isDisjoint(with: .footnote)
    }
}

extension ChatMessageLayoutOptions {
    var roundedCorners: CACornerMask {
        if contains(.continuousBubble) {
            return .all
        } else if contains(.flipped) {
            return CACornerMask.all.subtracting(.layerMaxXMaxYCorner)
        } else {
            return CACornerMask.all.subtracting(.layerMinXMaxYCorner)
        }
    }
}

extension ChatMessageContentView {
    @available(*, deprecated, renamed: "onlyVisibleToYouImageView")
    public var onlyVisibleForYouIconImageView: UIImageView? {
        onlyVisibleToYouImageView
    }
    
    @available(*, deprecated, renamed: "onlyVisibleToYouLabel")
    public var onlyVisibleForYouLabel: UILabel? {
        onlyVisibleToYouLabel
    }
    
    @available(*, deprecated, renamed: "onlyVisibleToYouContainer")
    public var onlyVisibleForYouContainer: ContainerStackView? {
        onlyVisibleToYouContainer
    }
    
    @available(*, deprecated, renamed: "footnoteContainer")
    public var metadataContainer: ContainerStackView? {
        footnoteContainer
    }
    
    @available(*, deprecated, renamed: "bubbleThreadFootnoteContainer")
    public var bubbleThreadMetaContainer: ContainerStackView? {
        bubbleThreadFootnoteContainer
    }
    
    @available(*, deprecated, renamed: "createOnlyVisibleToYouImageView")
    open func createOnlyVisibleForYouIconImageView() -> UIImageView {
        createOnlyVisibleToYouImageView()
    }
    
    @available(*, deprecated, renamed: "createOnlyVisibleToYouLabel")
    open func createOnlyVisibleForYouLabel() -> UILabel {
        createOnlyVisibleToYouLabel()
    }
}
