//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageReactionAuthorsVC:
    _ViewController,
    ThemeProvider,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout {
    /// The content of reaction authors view.
    public struct Content {
        /// The reactions of the message.
        public var reactions: [ChatMessageReaction]

        public init(
            reactions: [ChatMessageReaction]
        ) {
            self.reactions = reactions
        }
    }

    /// The content of reaction authors view.
    open var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The message controller of message that the reactions belong.
    open var messageController: ChatMessageController!

    /// Label that shows how many reactions the message has.
    open private(set) lazy var topLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory

    /// `UICollectionViewFlowLayout` instance for the collection view.
    open private(set) lazy var flowLayout: UICollectionViewFlowLayout = .init()

    /// `UICollectionView` instance to display the reaction authors.
    open private(set) lazy var collectionView: UICollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: flowLayout
    ).withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()

        collectionView.register(
            components.reactionAuthorsCell.self,
            forCellWithReuseIdentifier: components.reactionAuthorsCell.reuseId
        )

        collectionView.collectionViewLayout = flowLayout
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.isPagingEnabled = true
        collectionView.alwaysBounceVertical = false
        collectionView.alwaysBounceHorizontal = false

        if let message = messageController?.message, message.reactionScores.count <= 10 {
            content = .init(reactions: Array(message.latestReactions))
            collectionView.reloadData()
        } else {
            // TODO: Perform call
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.backgroundColor = appearance.colorPalette.background

        flowLayout.scrollDirection = .vertical
        flowLayout.sectionInset = .init(top: 0, left: 16, bottom: 0, right: 16)
        flowLayout.minimumLineSpacing = 20
        flowLayout.minimumInteritemSpacing = 4

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false

        topLabel.font = appearance.fonts.title3
        topLabel.textColor = appearance.colorPalette.text
        topLabel.textAlignment = .center
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(topLabel)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            topLabel.topAnchor.pin(equalTo: view.topAnchor, constant: 16),
            topLabel.leadingAnchor.pin(equalTo: view.leadingAnchor),
            topLabel.trailingAnchor.pin(equalTo: view.trailingAnchor),
            collectionView.topAnchor.pin(equalTo: topLabel.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.pin(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.pin(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.pin(equalTo: view.bottomAnchor, constant: 24)
        ])
    }

    override open func updateContent() {
        super.updateContent()

        topLabel.text = "\(content?.reactions.count ?? 0) Message Reactions"
    }

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        content?.reactions.count ?? 0
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: components.reactionAuthorsCell.reuseId,
            for: indexPath
        ) as! ChatMessageReactionAuthorViewCell

        if let reactions = content?.reactions,
           let currentUserId = messageController?.client.currentUserId {
            cell.content = ChatMessageReactionAuthorViewCell.Content(
                reaction: reactions[indexPath.item],
                currentUserId: currentUserId
            )
        }

        return cell
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        // TODO: Try to make this automatic? Check GalleryVC
        CGSize(width: 64, height: 110)
    }
}
