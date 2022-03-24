//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view controller that shows suggestions of commands or mentions.
open class ChatSuggestionsVC: _ViewController,
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
    
    /// A closure to observer when an item is selected.
    public var didSelectItemAt: ((Int) -> Void)?
    
    /// Property to check if the suggestions view controller is currently presented.
    public var isPresented: Bool {
        view.superview != nil
    }
    
    /// The collection view of the commands.
    open private(set) lazy var collectionView: ChatSuggestionsCollectionView = components
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
                guard let self = self, let newSize = change.newValue else { return }
                
                // NOTE: The defaultRowHeight height value will be used only once to set visibleCells
                // once again, not looping it to 0 value so this controller can resize again.
                let cellHeight = collectionView.visibleCells.first?.bounds.height ?? self.defaultRowHeight
                
                let newHeight = min(newSize.height, cellHeight * self.numberOfVisibleRows)
                self.heightConstraints.constant = newHeight
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

open class ChatMessageComposerSuggestionsCommandDataSource: NSObject, UICollectionViewDataSource {
    open var collectionView: ChatSuggestionsCollectionView
    
    /// The list of commands.
    open var commands: [Command]
    
    /// The current types to override ui components.
    open var components: Components {
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
    public init(with commands: [Command], collectionView: ChatSuggestionsCollectionView) {
        self.commands = commands
        self.collectionView = collectionView

        super.init()

        registerCollectionViewCell()

        collectionView.register(
            ChatSuggestionsCollectionReusableView.self,
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
        ) as! ChatSuggestionsCollectionReusableView

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
            withReuseIdentifier: ChatCommandSuggestionCollectionViewCell.reuseId,
            for: indexPath
        ) as! ChatCommandSuggestionCollectionViewCell

        cell.components = components
        guard let command = commands[safe: indexPath.row] else {
            indexNotFoundAssertion()
            return cell
        }

        cell.commandView.content = command

        return cell
    }
}

open class ChatMessageComposerSuggestionsMentionDataSource: NSObject,
    UICollectionViewDataSource,
    ChatUserSearchControllerDelegate {
    /// internal cache for users
    private(set) var usersCache: [ChatUser]
    
    /// The collection view of the mentions.
    open var collectionView: ChatSuggestionsCollectionView
    
    /// The search controller to search for mentions.
    open var searchController: ChatUserSearchController
    
    /// The types to override ui components.
    var components: Components {
        collectionView.components
    }
    
    /// Data Source Initialiser
    /// - Parameters:
    ///   - collectionView: The collection view of the mentions.
    ///   - searchController: The search controller to find mentions.
    ///   - usersCache: The initial results
    init(
        collectionView: ChatSuggestionsCollectionView,
        searchController: ChatUserSearchController,
        usersCache: [ChatUser] = []
    ) {
        self.collectionView = collectionView
        self.searchController = searchController
        self.usersCache = usersCache
        super.init()
        registerCollectionViewCell()
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?
            .headerReferenceSize = CGSize(width: self.collectionView.frame.size.width, height: 0)
        searchController.delegate = self
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
        usersCache.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ChatMentionSuggestionCollectionViewCell.reuseId,
            for: indexPath
        ) as! ChatMentionSuggestionCollectionViewCell

        guard let user = usersCache[safe: indexPath.row] else {
            indexNotFoundAssertion()
            return cell
        }
        // We need to make sure we set the components before accessing the mentionView,
        // so the mentionView is created with the most up-to-dated components.
        cell.components = components
        cell.mentionView.content = user
        return cell
    }

    public func controller(
        _ controller: ChatUserSearchController,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) {
        usersCache = searchController.userArray
        collectionView.reloadData()
    }
}
