//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

// MARK: - Reaction

open class ChatMessageReactionView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    open var content: ChatMessageReactionsView<ExtraData>.Reaction? { didSet { updateContentIfNeeded() } }
    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        return imageView
    }()

    open var notSelectedByUserTintColor: UIColor = .systemGray { didSet { updateContentIfNeeded() } }
    open var onTap: (MessageReactionType) -> Void = { _ in }
    open var isBig: Bool = true { didSet { updateContentIfNeeded() } }

    override open func setUp() {
        super.setUp()
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }

    override open func setUpLayout() {
        super.setUpLayout()
        embed(imageView)
    }

    override open func updateContent() {
        super.updateContent()
        guard let content = self.content else { return }

        imageView.image = isBig
            ? uiConfig.messageList.messageReactions.bigIconForMessageReaction(content.type)
            : uiConfig.messageList.messageReactions.smallIconForMessageReaction(content.type)

        imageView.tintColor = content.isSelectedByCurrentUser
            ? tintColor
            : notSelectedByUserTintColor
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        updateContentIfNeeded()
    }

    @objc open func didTap() {
        guard let content = self.content else { return }
        onTap(content.type)
    }
}

// MARK: - Reactions

/// Use `tailLeadingAnchor` and `tailTrailingAnchor` to snap bubble tail to reaction source.
/// Otherwise tail is located in the middle of reaction bubble
open class ChatMessageReactionsView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    public enum Height {
        public static var small: CGFloat { 24 }
        public static var big: CGFloat { 40 }
    }

    public enum Style {
        case bigIncoming
        case smallIncoming
        case bigOutgoing
        case smallOutgoing
    }

    public typealias Reaction = (type: MessageReactionType, isSelectedByCurrentUser: Bool)

    public private(set) lazy var heightConstraint: NSLayoutConstraint = heightAnchor.constraint(equalToConstant: Height.small)
    open var style: Style = .smallOutgoing {
        didSet { updateStyle() }
    }

    public var reactionViewType: ChatMessageReactionView<ExtraData>.Type {
        uiConfig.messageList.messageReactions.messageReactionView
    }

    open var onTap: (MessageReactionType) -> Void = { _ in } {
        didSet {
            content.arrangedSubviews.forEach { ($0 as? ChatMessageReactionView<ExtraData>)?.onTap = onTap }
        }
    }

    public let content: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = UIStackView.spacingUseSystem
        return stack
    }()

    public private(set) lazy var tailBehind = UIImageView().withoutAutoresizingMaskConstraints
    public private(set) lazy var backgroundView = UIView().withoutAutoresizingMaskConstraints
    public private(set) lazy var tailInFront = UIImageView().withoutAutoresizingMaskConstraints

    public var tailLeadingAnchor: NSLayoutXAxisAnchor { tailBehind.leadingAnchor }
    public var tailTrailingAnchor: NSLayoutXAxisAnchor { tailBehind.trailingAnchor }

    override open func setUpLayout() {
        heightConstraint.isActive = true
        widthAnchor.constraint(greaterThanOrEqualTo: heightAnchor, multiplier: 1).isActive = true

        addSubview(tailBehind)
        embed(backgroundView)
        tailBehind.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor).with(priority: .defaultLow).isActive = true
        tailBehind.centerYAnchor.constraint(equalTo: backgroundView.bottomAnchor).isActive = true

        addSubview(tailInFront)
        tailInFront.centerYAnchor.constraint(equalTo: tailBehind.centerYAnchor).isActive = true
        tailInFront.centerXAnchor.constraint(equalTo: tailBehind.centerXAnchor).isActive = true

        addSubview(content)
        content.pin(to: layoutMarginsGuide)
    }

    override open func defaultAppearance() {
        backgroundColor = .clear
        backgroundView.layer.borderWidth = 1
        updateStyle()
    }

    /// For incoming message reactions we use outgoing message colors, and vice versa.
    /// In big state we always use incoming colors
    open func updateStyle() {
        let reactionTint: UIColor
        let screenBackground: UIColor
        let borderColor: UIColor
        let innerColor: UIColor
        var isIncoming: Bool
        let isBig = style ~= .bigIncoming || style ~= .bigOutgoing

        switch style {
        case .bigIncoming:
            heightConstraint.constant = Height.big
            backgroundView.layer.cornerRadius = Height.big / 2
            innerColor = uiConfig.colorPalette.incomingMessageBubbleBackground
            borderColor = uiConfig.colorPalette.incomingMessageBubbleBackground
            reactionTint = uiConfig.colorPalette.incomingMessageInactiveReaction
            directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            screenBackground = .clear
            isIncoming = true

        case .bigOutgoing:
            heightConstraint.constant = Height.big
            backgroundView.layer.cornerRadius = Height.big / 2
            innerColor = uiConfig.colorPalette.incomingMessageBubbleBackground
            borderColor = uiConfig.colorPalette.incomingMessageBubbleBackground
            reactionTint = uiConfig.colorPalette.outgoingMessageInactiveReaction
            directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            screenBackground = .clear
            isIncoming = false

        case .smallIncoming:
            heightConstraint.constant = Height.small
            backgroundView.layer.cornerRadius = Height.small / 2
            innerColor = uiConfig.colorPalette.outgoingMessageBubbleBackground
            borderColor = uiConfig.colorPalette.outgoingMessageBubbleBorder
            reactionTint = uiConfig.colorPalette.incomingMessageInactiveReaction
            directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
            screenBackground = uiConfig.colorPalette.generalBackground
            isIncoming = true

        case .smallOutgoing:
            heightConstraint.constant = Height.small
            backgroundView.layer.cornerRadius = Height.small / 2
            innerColor = uiConfig.colorPalette.incomingMessageBubbleBackground
            borderColor = uiConfig.colorPalette.incomingMessageBubbleBorder
            reactionTint = uiConfig.colorPalette.outgoingMessageInactiveReaction
            directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
            screenBackground = uiConfig.colorPalette.generalBackground
            isIncoming = false
        }

        if traitCollection.layoutDirection == .rightToLeft {
            isIncoming.toggle()
        }

        backgroundView.backgroundColor = innerColor
        backgroundView.layer.borderColor = borderColor.cgColor

        if isBig {
            tailBehind.image = uiConfig.messageList.messageReactions.reactionViewHugeTail(innerColor, isIncoming)
            tailInFront.image = nil
        } else {
            let tails = uiConfig.messageList.messageReactions
                .reactionViewTail(screenBackground, borderColor, innerColor, isIncoming)
            tailBehind.image = tails.bottom
            tailInFront.image = tails.top
        }

        content.arrangedSubviews.forEach { view in
            (view as? ChatMessageReactionView<ExtraData>)?.notSelectedByUserTintColor = reactionTint
            (view as? ChatMessageReactionView<ExtraData>)?.isBig = isBig
        }
    }

    open func update(with reactions: [Reaction]) {
        content.arrangedSubviews.forEach { $0.removeFromSuperview() }
        reactions.forEach { reaction in
            let view = uiConfig.messageList.messageReactions.messageReactionView.init()
            view.content = reaction
            view.onTap = onTap
            content.addArrangedSubview(view)
        }
        updateStyle()
    }

    open func reload(from message: _ChatMessage<ExtraData>?, with allReactions: [MessageReactionType]? = nil) {
        guard let message = message else {
            update(with: [])
            return
        }
        let userReactions = Set(message.currentUserReactions.map(\.type))
        let rawReactions = allReactions ?? Array(message.reactionScores.keys)
        let reactions: [ChatMessageReactionsView.Reaction] = rawReactions
            .sorted { $0.rawValue < $1.rawValue }
            .map { ($0, userReactions.contains($0)) }
        update(with: reactions)
    }
}

// MARK: - Controller

open class ChatMessageReactionViewController<ExtraData: ExtraDataTypes>: ViewController, UIConfigProvider {
    public var messageController: _ChatMessageController<ExtraData>!

    // MARK: - Subviews

    public private(set) lazy var reactionsView = uiConfig
        .messageList
        .messageReactions
        .messageReactionsView
        .init()
        .withoutAutoresizingMaskConstraints

    // MARK: - Life Cycle

    override open func setUp() {
        super.setUp()

        messageController.setDelegate(self)
        reactionsView.onTap = { [weak self] in self?.toggleReaction($0) }
    }

    override public func defaultAppearance() {
        reactionsView.style = messageController.message?.isSentByCurrentUser == true ? .bigOutgoing : .bigIncoming
    }

    override open func setUpLayout() {
        view.embed(reactionsView)
    }

    override open func updateContent() {
        reactionsView.reload(
            from: messageController.message,
            with: uiConfig.messageList.messageReactions.messageAvailableReactions
        )
    }

    // MARK: - Actions

    public func toggleReaction(_ reaction: MessageReactionType) {
        guard let message = messageController.message else { return }

        let shouldRemove = message.currentUserReactions.contains { $0.type == reaction }
        shouldRemove
            ? messageController.deleteReaction(reaction)
            : messageController.addReaction(reaction)
    }
}

// MARK: - _MessageControllerDelegate

extension ChatMessageReactionViewController: _MessageControllerDelegate {
    public func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeMessage change: EntityChange<_ChatMessage<ExtraData>>
    ) {
        switch change {
        case .create, .remove: break
        case .update: updateContentIfNeeded()
        }
    }
}
