//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackReactionsView: _View, ThemeProvider, UICollectionViewDataSource, UICollectionViewDelegate {
    var content: ChatMessage? {
        didSet { updateContent() }
    }

    var reactions: [ChatMessageReactionData] = []

    lazy var messageController: ChatMessageController? = {
        guard let content = content else { return nil }
        guard let cid = content.cid else { return nil }

        return ChatClient.shared.messageController(
            cid: cid,
            messageId: content.id
        )
    }()

    let reactionWidth: CGFloat = 40
    let reactionRowHeight: CGFloat = 30

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SlackReactionsItemView.self, forCellWithReuseIdentifier: "SlackReactionsItemViewCell")
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        return collectionView
    }()

    private var collectionViewLayout: UICollectionViewCompositionalLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .estimated(reactionWidth), heightDimension: .absolute(24))
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(24)
            ),
            subitems: [item]
        )
        group.interItemSpacing = .fixed(4)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 4

        return UICollectionViewCompositionalLayout(section: section)
    }

    var heightConstraint: NSLayoutConstraint?

    override func setUpLayout() {
        super.setUpLayout()

        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        heightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint?.isActive = true
    }

    override func updateContent() {
        super.updateContent()

        guard let content = self.content else { return }

        reactions = content.reactionScores.map {
            let userReactionIDs = Set(content.currentUserReactions.map(\.type))
            return ChatMessageReactionData(
                type: $0.key,
                score: $0.value,
                isChosenByCurrentUser: userReactionIDs.contains($0.key)
            )
        }
        .sorted(by: components.reactionsSorting)

        collectionView.reloadData()

        let numberOfRows = Double(reactions.count) * reactionWidth / UIScreen.main.bounds.width
        heightConstraint?.constant = ceil(numberOfRows) * reactionRowHeight
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        reactions.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "SlackReactionsItemViewCell",
            for: indexPath
        ) as? SlackReactionsItemView else {
            return UICollectionViewCell()
        }

        cell.reaction = reactions[indexPath.item]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let reaction = reactions[indexPath.item]
        if reaction.isChosenByCurrentUser {
            messageController?.deleteReaction(reaction.type)
        } else {
            messageController?.addReaction(reaction.type)
        }
    }
}
