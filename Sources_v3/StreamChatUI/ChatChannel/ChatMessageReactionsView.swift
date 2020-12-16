//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

// MARK: - Reaction

class MessageReactionView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    var reaction: MessageReactionType? { didSet { updateContentIfNeeded() } }
    var madeByCurrentUser: Bool = false { didSet { updateContentIfNeeded() } }
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        return imageView
    }()

    var selectedByUserTintColor: UIColor { tintColor }
    var notSelectedByUserTintColor: UIColor = .systemGray { didSet { updateContentIfNeeded() } }
    var onTap: (MessageReactionType) -> Void = { _ in }
    var isBig: Bool = true { didSet { updateContentIfNeeded() } }

    override func setUp() {
        super.setUp()
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }

    override func setUpLayout() {
        super.setUpLayout()
        embed(imageView)
    }

    override func updateContent() {
        super.updateContent()
        guard let reaction = self.reaction else { return }

        imageView.image = isBig
            ? uiConfig.messageList.bigIconForMessageReaction(reaction)
            : uiConfig.messageList.smallIconForMessageReaction(reaction)

        imageView.tintColor = madeByCurrentUser
            ? selectedByUserTintColor
            : notSelectedByUserTintColor
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateContentIfNeeded()
    }

    @objc private func didTap() {
        guard let reaction = self.reaction else { return }
        onTap(reaction)
    }
}

// MARK: - Reactions

open class ChatMessageReactionsView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    private enum Height {
        static var small: CGFloat { 24 }
        static var big: CGFloat { 40 }
    }

    enum Style {
        case bigIncoming
        case smallIncoming
        case bigOutgoing
        case smallOutgoing
    }

    typealias Reaction = (type: MessageReactionType, isSelectedByCurrentUser: Bool)

    private lazy var heightConstraint: NSLayoutConstraint = heightAnchor.constraint(equalToConstant: Height.small)
    var style: Style = .smallOutgoing {
        didSet { updateStyle() }
    }

    var onTap: (MessageReactionType) -> Void = { _ in } {
        didSet {
            content.arrangedSubviews.forEach { ($0 as? MessageReactionView<ExtraData>)?.onTap = onTap }
        }
    }

    let content: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = UIStackView.spacingUseSystem
        return stack
    }()

    override open func setUpLayout() {
        heightConstraint.isActive = true
        addSubview(content)
        content.pin(to: layoutMarginsGuide)
    }

    override public func defaultAppearance() {
        layer.borderWidth = 1
        updateStyle()
    }

    func updateStyle() {
        /// for incoming message reactions we use outgoing message colors, and vice versa
        let reactionTint: UIColor
        switch style {
        case .bigIncoming:
            heightConstraint.constant = Height.big
            layer.cornerRadius = Height.big / 2
            backgroundColor = uiConfig.colorPalette.outgoingMessageBubbleBackground
            layer.backgroundColor = uiConfig.colorPalette.outgoingMessageBubbleBorder.cgColor
            reactionTint = .lightGray
            directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

        case .bigOutgoing:
            heightConstraint.constant = Height.big
            layer.cornerRadius = Height.big / 2
            backgroundColor = uiConfig.colorPalette.incomingMessageBubbleBackground
            layer.backgroundColor = uiConfig.colorPalette.incomingMessageBubbleBorder.cgColor
            reactionTint = .darkGray
            directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

        case .smallIncoming:
            heightConstraint.constant = Height.small
            layer.cornerRadius = Height.small / 2
            backgroundColor = uiConfig.colorPalette.outgoingMessageBubbleBackground
            layer.backgroundColor = uiConfig.colorPalette.outgoingMessageBubbleBorder.cgColor
            reactionTint = .lightGray
            directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)

        case .smallOutgoing:
            heightConstraint.constant = Height.small
            layer.cornerRadius = Height.small / 2
            backgroundColor = uiConfig.colorPalette.incomingMessageBubbleBackground
            layer.backgroundColor = uiConfig.colorPalette.incomingMessageBubbleBorder.cgColor
            reactionTint = .darkGray
            directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        }
        content.arrangedSubviews.forEach { view in
            (view as? MessageReactionView<ExtraData>)?.notSelectedByUserTintColor = reactionTint
            (view as? MessageReactionView<ExtraData>)?.isBig = style ~= .bigIncoming || style ~= .bigOutgoing
        }
    }

    private func update(with reactions: [Reaction]) {
        content.arrangedSubviews.forEach { $0.removeFromSuperview() }
        reactions.forEach { reaction in
            let view = MessageReactionView<ExtraData>()
            view.reaction = reaction.type
            view.madeByCurrentUser = reaction.isSelectedByCurrentUser
            view.onTap = onTap
            content.addArrangedSubview(view)
        }
        updateStyle()
    }

    func reload<T>(from message: _ChatMessage<T>?, with allReactions: [MessageReactionType]? = nil) {
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

    private lazy var reactionsView = uiConfig
        .messageList
        .messageReactionsView.init()
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
            with: uiConfig.messageList.messageAvailableReactions
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
