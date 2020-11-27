//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

// MARK: - Reaction

class MessageReactionView: UIView {
    var reaction: MessageReactionType? { didSet { updateReaction() } }
    var madeByCurrentUser: Bool = false { didSet { updateTints() } }
    private let imageView = UIImageView()
    private let emojiView: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .largeTitle)
        return label
    }()

    var selectedByUserTintColor: UIColor = .systemBlue { didSet { updateTints() } }
    var notSelectedByUserTintColor: UIColor = .systemGray { didSet { updateTints() } }
    var onTap: (MessageReactionType) -> Void = { _ in }

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

class ChatMessageReactionsView: UIView {
    private enum Height {
        static let small: CGFloat = 24
        static let big: CGFloat = 40
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        heightConstraint.isActive = true
        addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        content.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        content.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        content.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
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
            backgroundColor = .outgoingMessageBubbleBackground
            layer.backgroundColor = UIColor.outgoingMessageBubbleBorder.cgColor
            reactionTint = .lightGray

        case .bigOutgoing:
            heightConstraint.constant = Height.big
            layer.cornerRadius = Height.big / 2
            backgroundColor = .incomingMessageBubbleBackground
            layer.backgroundColor = UIColor.incomingMessageBubbleBorder.cgColor
            reactionTint = .darkGray

        case .smallIncoming:
            heightConstraint.constant = Height.small
            layer.cornerRadius = Height.small / 2
            backgroundColor = .outgoingMessageBubbleBackground
            layer.backgroundColor = UIColor.outgoingMessageBubbleBorder.cgColor
            reactionTint = .lightGray

        case .smallOutgoing:
            heightConstraint.constant = Height.small
            layer.cornerRadius = Height.small / 2
            backgroundColor = .incomingMessageBubbleBackground
            layer.backgroundColor = UIColor.incomingMessageBubbleBorder.cgColor
            reactionTint = .darkGray
        }
        content.arrangedSubviews.forEach { view in
            (view as? MessageReactionView)?.selectedByUserTintColor = .systemBlue
            (view as? MessageReactionView)?.notSelectedByUserTintColor = reactionTint
        }
    }

    func update(with reactions: [Reaction]) {
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
}

// MARK: - Controller

class ChatMessageReactionViewController<ExtraData: UIExtraDataTypes> {
    private let controller: _ChatMessageController<ExtraData>

    let view = ChatMessageReactionsView()
    let showAllAvailableReactions: Bool

    init(showAllAvailableReactions: Bool, messageID: MessageId, channel: ChannelId, client: _ChatClient<ExtraData>) {
        self.showAllAvailableReactions = showAllAvailableReactions
        controller = client.messageController(cid: channel, messageId: messageID)
        controller.setDelegate(self)
        view.onTap = { [weak self] in self?.toggleReaction($0) }
        reloadView()
    }

    func reloadView() {
        guard let message = controller.message else { return }
        let userReactions = Set(message.currentUserReactions.map(\.type))
        let reactions: [ChatMessageReactionsView.Reaction] = getReactions(for: message)
            .map { ($0, userReactions.contains($0)) }
        view.update(with: reactions)
    }

    func toggleReaction(_ reaction: MessageReactionType) {
        var a = [1]
        a.append(contentsOf: [2])
        guard let message = controller.message else { return }
        let shouldRemove = message.currentUserReactions.contains { $0.type == reaction }
        shouldRemove
            ? controller.deleteReaction(reaction)
            : controller.addReaction(reaction)
    }

    private func getReactions(for message: _ChatMessage<ExtraData>) -> [MessageReactionType] {
        if showAllAvailableReactions {
            return ["like", "haha", "facepalm", "roar", "You not expected this"].map(MessageReactionType.init(rawValue:))
        }
        return Array(message.reactionScores.keys)
    }
}

extension ChatMessageReactionViewController: _MessageControllerDelegate {
    func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeMessage change: EntityChange<_ChatMessage<ExtraData>>
    ) {
        switch change {
        case .create, .remove: break
        case .update: reloadView()
        }
    }
}
