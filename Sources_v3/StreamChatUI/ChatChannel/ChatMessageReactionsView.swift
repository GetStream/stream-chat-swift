//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

// MARK: - Reaction

class MessageReactionView: UIView {
    var reaction: MessageReactionType? { didSet { updateReaction() } }
    var madeByCurrentUser: Bool = false { didSet { updateTints() } }
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private let emojiView: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    var selectedByUserTintColor: UIColor = .systemBlue { didSet { updateTints() } }
    var notSelectedByUserTintColor: UIColor = .systemGray { didSet { updateTints() } }
    var onTap: (MessageReactionType) -> Void = { _ in }
    var isBig: Bool = true {
        didSet {
            /// I don't think we should scale reactions size according to system font
            emojiView.font = isBig
                ? .preferredFont(forTextStyle: .largeTitle)
                : .preferredFont(forTextStyle: .body)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        embed(imageView)
        embed(emojiView)
        updateTints()
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }

    private func image(for reaction: MessageReactionType) -> UIImage? {
        if reaction.rawValue == "like", #available(iOS 13.0, *) {
            return UIImage(systemName: "hand.thumbsup.fill")
        }
        return nil
    }

    private func emoji(for reaction: MessageReactionType) -> String {
        ["like": "👍", "haha": "🙂", "facepalm": "🤦‍♀️", "roar": "🦁"][reaction.rawValue] ?? "🤷‍♀️"
    }

    private func updateReaction() {
        guard let reaction = self.reaction else {
            imageView.isHidden = true
            emojiView.isHidden = true
            return
        }

        if let image = self.image(for: reaction) {
            imageView.isHidden = false
            imageView.image = image
            emojiView.isHidden = true
            return
        }

        imageView.isHidden = true
        emojiView.isHidden = false
        emojiView.text = emoji(for: reaction)
    }

    private func updateTints() {
        let tint = madeByCurrentUser
            ? selectedByUserTintColor
            : notSelectedByUserTintColor
        imageView.tintColor = tint
        emojiView.tintColor = tint
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
            content.arrangedSubviews.forEach { ($0 as? MessageReactionView)?.onTap = onTap }
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
        content.translatesAutoresizingMaskIntoConstraints = false
        content.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        content.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        content.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        content.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).with(priority: .defaultHigh).isActive = true
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

        case .bigOutgoing:
            heightConstraint.constant = Height.big
            layer.cornerRadius = Height.big / 2
            backgroundColor = uiConfig.colorPalette.incomingMessageBubbleBackground
            layer.backgroundColor = uiConfig.colorPalette.incomingMessageBubbleBorder.cgColor
            reactionTint = .darkGray

        case .smallIncoming:
            heightConstraint.constant = Height.small
            layer.cornerRadius = Height.small / 2
            backgroundColor = uiConfig.colorPalette.outgoingMessageBubbleBackground
            layer.backgroundColor = uiConfig.colorPalette.outgoingMessageBubbleBorder.cgColor
            reactionTint = .lightGray

        case .smallOutgoing:
            heightConstraint.constant = Height.small
            layer.cornerRadius = Height.small / 2
            backgroundColor = uiConfig.colorPalette.incomingMessageBubbleBackground
            layer.backgroundColor = uiConfig.colorPalette.incomingMessageBubbleBorder.cgColor
            reactionTint = .darkGray
        }
        if isHidden {
            heightConstraint.constant = 0
        }
        content.arrangedSubviews.forEach { view in
            (view as? MessageReactionView)?.selectedByUserTintColor = .systemBlue
            (view as? MessageReactionView)?.notSelectedByUserTintColor = reactionTint
            (view as? MessageReactionView)?.isBig = style ~= .bigIncoming || style ~= .bigOutgoing
        }
    }

    private func update(with reactions: [Reaction]) {
        content.arrangedSubviews.forEach { $0.removeFromSuperview() }
        reactions.forEach { reaction in
            let view = MessageReactionView()
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
        .messageActionsSubviews
        .reactionsView
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
            with: uiConfig.messageList.messageActionsSubviews.availableReactions
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
