//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public enum SuggestionKind {
    case command(hints: [Command])
    case mention
}

public typealias ChatMessageComposerSuggestionsViewController = _ChatMessageComposerSuggestionsViewController<NoExtraData>

open class _ChatMessageComposerSuggestionsViewController<ExtraData: ExtraDataTypes>: ViewController,
    UIConfigProvider,
    UICollectionViewDelegate {
    // MARK: - Property

    public var dataSource: UICollectionViewDataSource? {
        didSet {
            updateContentIfNeeded()
        }
    }

    private var frameObserver: NSKeyValueObservation?

    /// Height for suggestion cell, this value should never be 0
    /// otherwise it causes loop for height of this controller and as a result this controller height will be 0 as well.
    /// Note: This value can be 1, it's just for purpose of 1 cell being visible.
    private let defaultRowHeight: CGFloat = 44

    open var numberOfVisibleRows: CGFloat = 4

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

    override public func defaultAppearance() {
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

public typealias ChatMessageComposerSuggestionsCommandDataSource = _ChatMessageComposerSuggestionsCommandDataSource<NoExtraData>

open class _ChatMessageComposerSuggestionsCommandDataSource<ExtraData: ExtraDataTypes>: NSObject, UICollectionViewDataSource {
    open var collectionView: _ChatMessageComposerSuggestionsCollectionView<ExtraData>
    open var commands: [Command]

    open var uiConfig: _UIConfig<ExtraData> {
        collectionView.uiConfig
    }

    public init(with commands: [Command], collectionView: _ChatMessageComposerSuggestionsCollectionView<ExtraData>) {
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

    public func collectionView(
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
        headerView.suggestionsHeader.commandImageView.image = UIImage(
            named: "bolt",
            in: .streamChatUI
        )?
            .tinted(with: headerView.tintColor)

        return headerView
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        commands.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: _ChatMessageComposerCommandCollectionViewCell<ExtraData>.reuseId,
            for: indexPath
        ) as! _ChatMessageComposerCommandCollectionViewCell<ExtraData>

        cell.uiConfig = uiConfig
        cell.commandView.command = commands[indexPath.row]

        return cell
    }
}

public typealias ChatMessageComposerSuggestionsMentionDataSource = _ChatMessageComposerSuggestionsMentionDataSource<NoExtraData>

open class _ChatMessageComposerSuggestionsMentionDataSource<ExtraData: ExtraDataTypes>: NSObject,
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

    public func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        UICollectionReusableView()
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        searchController.users.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: _ChatMessageComposerMentionCollectionViewCell<ExtraData>.reuseId,
            for: indexPath
        ) as! _ChatMessageComposerMentionCollectionViewCell<ExtraData>

        let user = searchController.users[indexPath.row]
        cell.mentionView.content = (user.name ?? "", user.id, user.imageURL, true)
        cell.uiConfig = uiConfig
        return cell
    }

    // MARK: - ChatUserSearchControllerDelegate

    public func controller(
        _ controller: _ChatUserSearchController<ExtraData>,
        didChangeUsers changes: [ListChange<_ChatUser<ExtraData.User>>]
    ) {
        collectionView.reloadData()
    }
}
