//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal enum SuggestionKind {
    case command(hints: [Command])
    case mention
}

internal typealias ChatMessageComposerSuggestionsViewController = _ChatMessageComposerSuggestionsViewController<NoExtraData>

internal class _ChatMessageComposerSuggestionsViewController<ExtraData: ExtraDataTypes>: _ViewController,
    UIConfigProvider,
    UICollectionViewDelegate {
    // MARK: - Property

    internal var dataSource: UICollectionViewDataSource? {
        didSet {
            updateContentIfNeeded()
        }
    }

    private var frameObserver: NSKeyValueObservation?

    /// Height for suggestion cell, this value should never be 0
    /// otherwise it causes loop for height of this controller and as a result this controller height will be 0 as well.
    /// Note: This value can be 1, it's just for purpose of 1 cell being visible.
    private let defaultRowHeight: CGFloat = 44

    internal var numberOfVisibleRows: CGFloat = 4

    /// View to which the suggestions should be pinned.
    /// This view should be assigned as soon as instance of this
    /// class is instantiated, because we set observer to
    /// the bottomAnchorView as soon as we compute the height of the
    /// contentSize of the nested collectionView
    internal var bottomAnchorView: UIView?

    internal var didSelectItemAt: ((Int) -> Void)?

    internal var isPresented: Bool {
        view.superview != nil
    }

    private var collectionViewHeightObserver: NSKeyValueObservation?

    // MARK: - Subviews

    internal private(set) lazy var collectionView = uiConfig
        .messageComposer
        .suggestionsCollectionView
        .init(layout: uiConfig.messageComposer.suggestionsCollectionViewLayout.init())
        .withoutAutoresizingMaskConstraints

    internal private(set) lazy var containerView: UIView = UIView().withoutAutoresizingMaskConstraints

    // MARK: - Overrides

    override internal func setUp() {
        super.setUp()

        collectionView.delegate = self
    }

    override internal func defaultAppearance() {
        view.backgroundColor = .clear
        view.layer.addShadow(color: uiConfig.colorPalette.shadow)
    }

    override internal func setUpLayout() {
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
            changeHandler: { [weak self] collectionView, change in
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    // NOTE: The defaultRowHeight height value will be used only once to set visibleCells
                    // once again, not looping it to 0 value so this controller can resize again.
                    let cellHeight = collectionView.visibleCells.first?.bounds.height ?? self.defaultRowHeight

                    guard let newSize = change.newValue,
                        newSize.height < cellHeight * self.numberOfVisibleRows
                    else {
                        self.view.frame.size.height = cellHeight * self.numberOfVisibleRows
                        self.updateViewFrame()
                        return
                    }
                    self.view.frame.size.height = newSize.height
                    self.updateViewFrame()
                }
            }
        )
        updateContent()
    }

    override internal func updateContent() {
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

    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectItemAt?(indexPath.row)
    }
}

internal typealias ChatMessageComposerSuggestionsCommandDataSource = _ChatMessageComposerSuggestionsCommandDataSource<NoExtraData>

internal class _ChatMessageComposerSuggestionsCommandDataSource<ExtraData: ExtraDataTypes>: NSObject, UICollectionViewDataSource {
    internal var collectionView: _ChatMessageComposerSuggestionsCollectionView<ExtraData>
    internal var commands: [Command]

    internal var uiConfig: _UIConfig<ExtraData> {
        collectionView.uiConfig
    }

    internal init(with commands: [Command], collectionView: _ChatMessageComposerSuggestionsCollectionView<ExtraData>) {
        self.commands = commands
        self.collectionView = collectionView

        super.init()

        registerCollectionViewCell()

        collectionView.register(
            _ChatMessageComposerSuggestionsCommandsReusableView<ExtraData>.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "CommandsHeader"
        )
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?
            .headerReferenceSize = CGSize(width: self.collectionView.frame.size.width, height: 40)
    }

    private func registerCollectionViewCell() {
        collectionView.register(
            uiConfig.messageComposer.suggestionsCommandCollectionViewCell,
            forCellWithReuseIdentifier: uiConfig.messageComposer.suggestionsCommandCollectionViewCell.reuseId
        )
    }

    internal func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "CommandsHeader",
            for: indexPath
        ) as! _ChatMessageComposerSuggestionsCommandsReusableView<ExtraData>

        headerView.suggestionsHeader.headerLabel.text = L10n.Composer.Suggestions.Commands.header
        headerView.suggestionsHeader.commandImageView.image = uiConfig.images.messageComposerCommand
            .tinted(with: headerView.tintColor)

        return headerView
    }

    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        commands.count
    }

    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: _ChatMessageComposerCommandCollectionViewCell<ExtraData>.reuseId,
            for: indexPath
        ) as! _ChatMessageComposerCommandCollectionViewCell<ExtraData>

        cell.uiConfig = uiConfig
        cell.commandView.content = commands[indexPath.row]

        return cell
    }
}

internal typealias ChatMessageComposerSuggestionsMentionDataSource = _ChatMessageComposerSuggestionsMentionDataSource<NoExtraData>

internal class _ChatMessageComposerSuggestionsMentionDataSource<ExtraData: ExtraDataTypes>: NSObject,
    UICollectionViewDataSource,
    _ChatUserSearchControllerDelegate {
    var collectionView: _ChatMessageComposerSuggestionsCollectionView<ExtraData>
    var searchController: _ChatUserSearchController<ExtraData>

    var uiConfig: _UIConfig<ExtraData> {
        collectionView.uiConfig
    }

    init(
        collectionView: _ChatMessageComposerSuggestionsCollectionView<ExtraData>,
        searchController: _ChatUserSearchController<ExtraData>
    ) {
        self.collectionView = collectionView
        self.searchController = searchController
        super.init()
        registerCollectionViewCell()
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?
            .headerReferenceSize = CGSize(width: self.collectionView.frame.size.width, height: 0)
        searchController.setDelegate(self)
    }

    private func registerCollectionViewCell() {
        collectionView.register(
            uiConfig.messageComposer.suggestionsMentionCollectionViewCell,
            forCellWithReuseIdentifier: uiConfig.messageComposer.suggestionsMentionCollectionViewCell.reuseId
        )
    }

    // MARK: - CollectionViewDataSource

    internal func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        UICollectionReusableView()
    }

    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        searchController.users.count
    }

    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: _ChatMessageComposerMentionCollectionViewCell<ExtraData>.reuseId,
            for: indexPath
        ) as! _ChatMessageComposerMentionCollectionViewCell<ExtraData>

        let user = searchController.users[indexPath.row]
        cell.mentionView.content = user
        cell.uiConfig = uiConfig
        return cell
    }

    // MARK: - ChatUserSearchControllerDelegate

    internal func controller(
        _ controller: _ChatUserSearchController<ExtraData>,
        didChangeUsers changes: [ListChange<_ChatUser<ExtraData.User>>]
    ) {
        collectionView.reloadData()
    }
}
