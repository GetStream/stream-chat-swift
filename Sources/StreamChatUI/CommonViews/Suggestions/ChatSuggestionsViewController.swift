//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view controller that shows suggestions of commands or mentions.
public typealias ChatSuggestionsViewController = _ChatSuggestionsViewController<NoExtraData>

/// A view controller that shows suggestions of commands or mentions.
open class _ChatSuggestionsViewController<ExtraData: ExtraDataTypes>: _ViewController,
    ThemeProvider,
    UICollectionViewDelegate {
    /// The data provider of the collection view. A custom `UICollectionViewDataSource` can be provided,
    /// by default `ChatMessageComposerSuggestionsCommandDataSource` is used.
    /// A subclass of `ChatMessageComposerSuggestionsCommandDataSource` can also be provided.
    public var dataSource: UICollectionViewDataSource? {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    /// The number of visible commands without scrolling.
    open var numberOfVisibleRows: CGFloat = 4

    /// View to which the suggestions should be pinned.
    /// This view should be assigned as soon as instance of this
    /// class is instantiated, because we set observer to
    /// the bottomAnchorView as soon as we compute the height of the
    /// contentSize of the nested collectionView
    public var bottomAnchorView: UIView?
    
    /// A closure to observer when an item is selected.
    public var didSelectItemAt: ((Int) -> Void)?
    
    /// Property to check if the suggestions view controller is currently presented.
    public var isPresented: Bool {
        view.superview != nil
    }
    
    /// The collection view of the commands.
    open private(set) lazy var collectionView: _ChatSuggestionsCollectionView<ExtraData> = components
        .suggestionsCollectionView
        .init(layout: components.suggestionsCollectionViewLayout.init())
        .withoutAutoresizingMaskConstraints
    
    /// The container view where collectionView is embedded.
    open private(set) lazy var containerView: UIView = UIView().withoutAutoresizingMaskConstraints

    // Height for suggestion cell, this value should never be 0
    // otherwise it causes loop for height of this controller and as a result this controller height will be 0 as well.
    // Note: This value can be 1, it's just for purpose of 1 cell being visible.
    private let defaultRowHeight: CGFloat = 44

    /// The constraints responsible for setting the height of the main view.
    public lazy var heightConstraints: NSLayoutConstraint = {
        let constraint = view.heightAnchor.pin(equalToConstant: 0)
        constraint.isActive = true
        return constraint
    }()
    
    private var collectionViewHeightObserver: NSKeyValueObservation?
    
    override open func setUp() {
        super.setUp()

        collectionView.delegate = self
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        view.backgroundColor = .clear
        view.layer.addShadow(color: appearance.colorPalette.shadow)
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
                    guard let self = self, let newSize = change.newValue else { return }

                    // NOTE: The defaultRowHeight height value will be used only once to set visibleCells
                    // once again, not looping it to 0 value so this controller can resize again.
                    let cellHeight = collectionView.visibleCells.first?.bounds.height ?? self.defaultRowHeight

                    let newHeight = min(newSize.height, cellHeight * self.numberOfVisibleRows)
                    self.heightConstraints.constant = newHeight
                }
            }
        )
    }

    override open func updateContent() {
        super.updateContent()
        
        collectionView.dataSource = dataSource
        collectionView.reloadData()
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectItemAt?(indexPath.row)
    }
}

public typealias ChatMessageComposerSuggestionsCommandDataSource = _ChatMessageComposerSuggestionsCommandDataSource<NoExtraData>

open class _ChatMessageComposerSuggestionsCommandDataSource<ExtraData: ExtraDataTypes>: NSObject, UICollectionViewDataSource {
    open var collectionView: _ChatSuggestionsCollectionView<ExtraData>
    
    /// The list of commands.
    open var commands: [Command]
    
    /// The current types to override ui components.
    open var components: _Components<ExtraData> {
        collectionView.components
    }
    
    /// The current types to override ui components.
    open var appearance: Appearance {
        collectionView.appearance
    }
    
    /// Data Source Initialiser
    ///
    /// - Parameters:
    ///   - commands: The list of commands.
    ///   - collectionView: The collection view of the commands.
    public init(with commands: [Command], collectionView: _ChatSuggestionsCollectionView<ExtraData>) {
        self.commands = commands
        self.collectionView = collectionView

        super.init()

        registerCollectionViewCell()

        collectionView.register(
            _ChatSuggestionsCollectionReusableView<ExtraData>.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "CommandsHeader"
        )
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?
            .headerReferenceSize = CGSize(width: self.collectionView.frame.size.width, height: 40)
    }

    private func registerCollectionViewCell() {
        collectionView.register(
            components.suggestionsCommandCollectionViewCell,
            forCellWithReuseIdentifier: components.suggestionsCommandCollectionViewCell.reuseId
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
        ) as! _ChatSuggestionsCollectionReusableView<ExtraData>

        headerView.suggestionsHeader.headerLabel.text = L10n.Composer.Suggestions.Commands.header
        headerView.suggestionsHeader.commandImageView.image = appearance.images.commands
            .tinted(with: headerView.tintColor)

        return headerView
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        commands.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: _ChatCommandSuggestionCollectionViewCell<ExtraData>.reuseId,
            for: indexPath
        ) as! _ChatCommandSuggestionCollectionViewCell<ExtraData>

        cell.components = components
        cell.commandView.content = commands[indexPath.row]

        return cell
    }
}

public typealias ChatMessageComposerSuggestionsMentionDataSource = _ChatMessageComposerSuggestionsMentionDataSource<NoExtraData>

open class _ChatMessageComposerSuggestionsMentionDataSource<ExtraData: ExtraDataTypes>: NSObject,
    UICollectionViewDataSource,
    _ChatUserSearchControllerDelegate {
    /// The collection view of the mentions.
    open var collectionView: _ChatSuggestionsCollectionView<ExtraData>
    
    /// The search controller to search for mentions.
    open var searchController: _ChatUserSearchController<ExtraData>
    
    /// The types to override ui components.
    var components: _Components<ExtraData> {
        collectionView.components
    }
    
    /// Data Source Initialiser
    /// - Parameters:
    ///   - collectionView: The collection view of the mentions.
    ///   - searchController: The search controller to find mentions.
    init(
        collectionView: _ChatSuggestionsCollectionView<ExtraData>,
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
            components.suggestionsMentionCollectionViewCell,
            forCellWithReuseIdentifier: components.suggestionsMentionCollectionViewCell.reuseId
        )
    }

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
            withReuseIdentifier: _ChatMentionSuggestionCollectionViewCell<ExtraData>.reuseId,
            for: indexPath
        ) as! _ChatMentionSuggestionCollectionViewCell<ExtraData>

        let user = searchController.users[indexPath.row]
        // We need to make sure we set the components before accessing the mentionView,
        // so the mentionView is created with the most up-to-dated components.
        cell.components = components
        cell.mentionView.content = user
        return cell
    }

    public func controller(
        _ controller: _ChatUserSearchController<ExtraData>,
        didChangeUsers changes: [ListChange<_ChatUser<ExtraData.User>>]
    ) {
        collectionView.reloadData()
    }
}
