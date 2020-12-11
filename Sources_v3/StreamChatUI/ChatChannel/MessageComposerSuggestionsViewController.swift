//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class MessageComposerSuggestionsViewController<ExtraData: ExtraDataTypes>: ViewController,
    UIConfigProvider,
    UICollectionViewDelegate,
    UICollectionViewDataSource {
    var heightConstraint: NSLayoutConstraint?

    // MARK: - Property

    private var collectionViewHeightObserver: NSKeyValueObservation?

    // MARK: - Subviews

    open private(set) lazy var collectionView = uiConfig
        .messageComposer
        .suggestionsCollectionView
        .init(layout: uiConfig.messageComposer.suggestionsCollectionViewLayout.init())
        .withoutAutoresizingMaskConstraints

    // MARK: - Overrides

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.embed(collectionView)
    }

    override open func setUp() {
        super.setUp()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            uiConfig.messageComposer.suggestionsCommandCollectionViewCell,
            forCellWithReuseIdentifier: uiConfig.messageComposer.suggestionsCommandCollectionViewCell.reuseId
        )
        collectionView.register(
            uiConfig.messageComposer.suggestionsMentionCollectionViewCell,
            forCellWithReuseIdentifier: uiConfig.messageComposer.suggestionsMentionCollectionViewCell.reuseId
        )
        
        collectionViewHeightObserver = collectionView.observe(
            \.contentSize,
            options: [.new],
            changeHandler: { [weak self] _, change in
                DispatchQueue.main.async {
                    guard let self = self, let newSize = change.newValue else { return }
                    self.heightConstraint?.constant = newSize.height
                    self.view.setNeedsLayout()
                }
            }
        )
    }

    override public func setUpAppearance() {
        view.backgroundColor = .clear
        view.layer.addShadow(color: uiConfig.colorPalette.shadow)
    }

    override public func setUpLayout() {
        view.translatesAutoresizingMaskIntoConstraints = false

        heightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 0)

        let constraints = [heightConstraint].compactMap { $0 }

        NSLayoutConstraint.activate(constraints)
        updateContent()
    }

    override open func updateViewConstraints() {
        super.updateViewConstraints()
        heightConstraint?.constant = collectionView.contentSize.height
    }

    override open func updateContent() {
        collectionView.reloadData()
    }

    // MARK: - UICollectionView

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        3 // uiConfig.commandIcons.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(
//            withReuseIdentifier: MessageComposerCommandCollectionViewCell<ExtraData>.reuseId,
//            for: indexPath
//        ) as! MessageComposerCommandCollectionViewCell<ExtraData>
//
//        cell.uiConfig = uiConfig
//        cell.commandView.content = ("Giphy", "/giphy [query]", UIImage(named: "command_giphy", in: .streamChatUI))

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MessageComposerMentionCollectionViewCell<ExtraData>.reuseId,
            for: indexPath
        ) as! MessageComposerMentionCollectionViewCell<ExtraData>

        cell.uiConfig = uiConfig
        cell.mentionView.content = ("Damian", "@damian", UIImage(named: "pattern1", in: .streamChatUI), false)

        return cell
    }
}
