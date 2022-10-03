//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackReactionsView: _View, AppearanceProvider {
    var content: ChatMessage? {
        didSet { updateContentIfNeeded() }
    }

    lazy var mainStackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = 2
        return view
    }()

    lazy var topStackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 5
        view.distribution = .equalSpacing
        return view
    }()

    lazy var bottomStackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 5
        view.distribution = .equalSpacing
        return view
    }()

    var heightConstraint: NSLayoutConstraint?

    let rowHeight: CGFloat = 26

    override func setUpLayout() {
        super.setUpLayout()

        addSubview(mainStackView)
        mainStackView.addArrangedSubview(topStackView)
        mainStackView.addArrangedSubview(bottomStackView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        heightConstraint = mainStackView.heightAnchor.constraint(equalToConstant: rowHeight)
        heightConstraint?.isActive = true
    }

    let productReactionsOrder = ["love", "like", "dislike", "haha", "wow", "sad"]

    override func updateContent() {
        super.updateContent()

        topStackView.subviews.forEach {
            $0.removeFromSuperview()
        }
        bottomStackView.subviews.forEach {
            $0.removeFromSuperview()
        }

        guard let content = content else { return }

        mainStackView.alignment = content.isSentByCurrentUser ? .trailing : .leading

        var reactionsWidth: CGFloat = 0.0

        for key in productReactionsOrder {
            let reactionType = MessageReactionType(rawValue: key)
            if let reactionScore = content.reactionScores[reactionType] {
                if let image = appearance.images.availableReactions[reactionType]?.smallIcon {
                    let reactionItemView = SlackReactionsItemView()
                    reactionItemView.setImage(image, for: .normal)
                    reactionItemView.setTitle(" \(reactionScore) ", for: .normal)
                    reactionItemView.onTap = {
                        let shouldRemove = content.currentUserReactions.contains { $0.type == reactionType }
                        let messageController = StreamChatWrapper.shared.client!.messageController(
                            cid: ChannelId(type: .team, id: content.cid?.id ?? ""),
                            messageId: content.id
                        )
                        shouldRemove ? messageController.deleteReaction(reactionType) : messageController.addReaction(reactionType)
                    }
                    if content.currentUserReactions.contains(where: { $0.type == reactionType }) {
                        reactionItemView.setTitleColor(.blue, for: .normal)
                        reactionItemView.backgroundColor = UIColor.blue.withAlphaComponent(0.2)
                    }

                    reactionsWidth += reactionItemView.intrinsicContentSize.width

                    if reactionsWidth < UIScreen.main.bounds.width {
                        topStackView.addArrangedSubview(reactionItemView)
                    } else {
                        bottomStackView.addArrangedSubview(reactionItemView)
                    }
                }
            }
        }

        if !bottomStackView.subviews.isEmpty && !topStackView.subviews.isEmpty {
            heightConstraint?.constant = rowHeight * 2
        } else {
            heightConstraint?.constant = rowHeight
        }
    }
}
