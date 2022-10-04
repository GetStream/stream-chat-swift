//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackReactionsView: _View, ThemeProvider {
    var content: ChatMessage? {
        didSet { updateContentIfNeeded() }
    }

    lazy var messageController: ChatMessageController? = {
        guard let content = content else { return nil }
        guard let cid = content.cid else { return nil }

        return StreamChatWrapper.shared.messageController(
            cid: cid,
            messageId: content.id
        )
    }()

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

        let userReactionIDs = Set(content.currentUserReactions.map(\.type))
        let reactions = content.reactionScores
            .map { ChatMessageReactionData(
                type: $0.key,
                score: $0.value,
                isChosenByCurrentUser: userReactionIDs.contains($0.key)
            ) }

        reactions.sorted(by: components.reactionsSorting).forEach { reaction in
            guard let reactionImage = appearance.images.availableReactions[reaction.type] else {
                return
            }

            let reactionItemView = SlackReactionsItemView()
            reactionItemView.setImage(reactionImage.smallIcon, for: .normal)
            reactionItemView.setTitle(" \(reaction.score) ", for: .normal)
            reactionItemView.onTap = { [weak self] in
                if reaction.isChosenByCurrentUser {
                    self?.messageController?.deleteReaction(reaction.type)
                } else {
                    self?.messageController?.addReaction(reaction.type)
                }
            }

            if reaction.isChosenByCurrentUser {
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
