//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public enum SuggestionKind {
    case command(hints: [Command])
    case mention
}

open class MessageComposerSuggestionsViewController<ExtraData: ExtraDataTypes>: ViewController,
    UIConfigProvider,
    UICollectionViewDelegate {
    // MARK: - Property

    public var dataSource: UICollectionViewDataSource?

    private var frameObserver: NSKeyValueObservation?

    /// View to which the suggestions should be pinned.
    /// This view should be assigned as soon as instance of this
    /// class is instantiated, because we set observer to
    /// the bottomAnchorView as soon as we compute the height of the
    /// contentSize of the nested collectionView
    public var bottomAnchorView: UIView?

    public var didSelectItemAt: ((Int) -> Void)?

    public var isPresented: Bool {
        view.superview != nil
    }

    private var collectionViewHeightObserver: NSKeyValueObservation?

    // MARK: - Subviews

    open private(set) lazy var collectionView = uiConfig
        .messageComposer
        .suggestionsCollectionView
        .init(layout: uiConfig.messageComposer.suggestionsCollectionViewLayout.init())
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var containerView: UIView = UIView().withoutAutoresizingMaskConstraints

    // MARK: - Overrides

    override open func setUp() {
        super.setUp()

        collectionView.delegate = self
    }

    override open func setUpAppearance() {
        view.backgroundColor = .clear
        view.layer.addShadow(color: uiConfig.colorPalette.shadow)
    }

    override open func setUpLayout() {
        view.embed(containerView)
        containerView.embed(
            collectionView,
            insets: .init(
                top: 0,
                leading: containerView.directionalLayoutMargins.leading,
                bottom: 0,
                trailing: containerView.directionalLayoutMargins.trailing
            )
        )

        collectionViewHeightObserver = collectionView.observe(
            \.contentSize,
            options: [.new],
            changeHandler: { [weak self] _, change in
                DispatchQueue.main.async {
                    guard let newSize = change.newValue, newSize.height < 230 else {
                        // TODO: Compute size better according to 4 cells.
                        self?.view.frame.size.height = 230
                        self?.updateViewFrame()
                        return
                    }
                    self?.view.frame.size.height = newSize.height
                    self?.updateViewFrame()
                }
            }
        )
        updateContent()
    }

    override open func updateContent() {
        collectionView.dataSource = dataSource
        collectionView.reloadData()
    }

    // MARK: - Private

    private func updateViewFrame() {
        frameObserver = bottomAnchorView?.observe(
            \.bounds,
            options: [.new, .initial],
            changeHandler: { [weak self] bottomAnchoredView, change in
                DispatchQueue.main.async {
                    guard let self = self, let changedFrame = change.newValue else { return }

                    let newFrame = bottomAnchoredView.convert(changedFrame, to: nil)
                    self.view.frame.origin.y = newFrame.minY - self.view.frame.height
                }
            }
        )
    }

    // MARK: - UICollectionView

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectItemAt?(indexPath.row)
    }
}

class SuggestionsCommandDataSource<ExtraData: ExtraDataTypes>: NSObject, UICollectionViewDataSource {
    var collectionView: MessageComposerSuggestionsCollectionView<ExtraData>
    var commands: [Command]

    var uiConfig: UIConfig<ExtraData> {
        collectionView.uiConfig()
    }

    init(with commands: [Command], collectionView: MessageComposerSuggestionsCollectionView<ExtraData>) {
        self.commands = commands
        self.collectionView = collectionView

        super.init()

        registerCollectionViewCell()
    }

    private func registerCollectionViewCell() {
        collectionView.register(
            uiConfig.messageComposer.suggestionsCommandCollectionViewCell,
            forCellWithReuseIdentifier: uiConfig.messageComposer.suggestionsCommandCollectionViewCell.reuseId
        )
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        commands.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MessageComposerCommandCollectionViewCell<ExtraData>.reuseId,
            for: indexPath
        ) as! MessageComposerCommandCollectionViewCell<ExtraData>

        cell.uiConfig = uiConfig
        cell.commandView.command = commands[indexPath.row]

        return cell
    }
}

class SuggestionsMentionDataSource<ExtraData: ExtraDataTypes>: NSObject,
    UICollectionViewDataSource,
    _ChatUserSearchControllerDelegate {
    var collectionView: MessageComposerSuggestionsCollectionView<ExtraData>
    var searchController: _ChatUserSearchController<ExtraData>

    var uiConfig: UIConfig<ExtraData> {
        collectionView.uiConfig()
    }

    init(
        collectionView: MessageComposerSuggestionsCollectionView<ExtraData>,
        searchController: _ChatUserSearchController<ExtraData>
    ) {
        self.collectionView = collectionView
        self.searchController = searchController
        super.init()
        registerCollectionViewCell()
        searchController.setDelegate(self)
    }

    private func registerCollectionViewCell() {
        collectionView.register(
            uiConfig.messageComposer.suggestionsMentionCollectionViewCell,
            forCellWithReuseIdentifier: uiConfig.messageComposer.suggestionsMentionCollectionViewCell.reuseId
        )
    }

    // MARK: - CollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        searchController.users.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MessageComposerMentionCollectionViewCell<ExtraData>.reuseId,
            for: indexPath
        ) as! MessageComposerMentionCollectionViewCell<ExtraData>

        let user = searchController.users[indexPath.row]
        cell.mentionView.content = (user.name ?? "", user.id, user.imageURL, true)
        cell.uiConfig = uiConfig
        return cell
    }

    // MARK: - ChatUserSearchControllerDelegate

    func controller(
        _ controller: _ChatUserSearchController<ExtraData>,
        didChangeUsers changes: [ListChange<_ChatUser<ExtraData.User>>]
    ) {
        collectionView.reloadData()
    }
}
