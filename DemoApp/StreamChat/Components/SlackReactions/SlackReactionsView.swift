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

        // If both stack views have content, increase the size of the main stack
        if !bottomStackView.subviews.isEmpty && !topStackView.subviews.isEmpty {
            heightConstraint?.constant = rowHeight * 2
        } else {
            heightConstraint?.constant = rowHeight
        }
    }
}

class SlackReactionsCollectionViewCell: UICollectionViewCell {
    var reaction: ChatMessageReactionData? {
        didSet {
            guard let reaction = reaction else {
                return
            }

            textLabel.text = "🙂 \(reaction.score)"
            textLabel.textColor = reaction.isChosenByCurrentUser ? .blue : .gray
        }
    }

    private let reactionHeight: CGFloat = 26

    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 11)
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = frame.height / 2
        backgroundColor = .lightGray.withAlphaComponent(0.5)
    }

    private func configureView() {
        addSubview(textLabel)
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            textLabel.widthAnchor.constraint(equalToConstant: 35),
            textLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
}

final class SlackReactionsListView: _View, ThemeProvider, UICollectionViewDataSource, UICollectionViewDelegate {
    var content: ChatMessage? {
        didSet { updateContent() }
    }

    var reactions: [ChatMessageReactionData] = []

    lazy var messageController: ChatMessageController? = {
        guard let content = content else { return nil }
        guard let cid = content.cid else { return nil }

        return StreamChatWrapper.shared.messageController(
            cid: cid,
            messageId: content.id
        )
    }()

    let reactionWidth: CGFloat = 40
    let reactionRowHeight: CGFloat = 30

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = CGSize(width: reactionWidth, height: 24)
        layout.minimumInteritemSpacing = 4
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SlackReactionsCollectionViewCell.self, forCellWithReuseIdentifier: "ReactionCell")
        collectionView.backgroundColor = .clear
        collectionView.semanticContentAttribute = .forceRightToLeft
        collectionView.isScrollEnabled = false
        return collectionView
    }()

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
        reactions += reactions

        collectionView.reloadData()

        let lines = CGFloat(reactions.count) * reactionWidth / UIScreen.main.bounds.width
        heightConstraint?.constant = ceil(lines) * reactionRowHeight
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        reactions.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ReactionCell", for: indexPath
        ) as! SlackReactionsCollectionViewCell

        cell.reaction = reactions[indexPath.item]
        return cell
    }
}
