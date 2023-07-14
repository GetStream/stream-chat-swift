//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view controller responsible to search messages.
open class ChatMessageSearchVC: ChatChannelListVC, UISearchResultsUpdating, ChatMessageSearchControllerDelegate {
    /// The `ChatMessageSearchController` instance to perform the messages search.
    public var messageSearchController: ChatMessageSearchController!

    /// The closure that is triggered whenever a message is selected from the search result.
    public var didSelectMessage: ((ChatChannel, ChatMessage) -> Void)?

    /// The component responsible to debounce search requests.
    public var debouncer = Debouncer(0.3, queue: .main)

    /// The current active search text.
    public var currentSearchText: String = ""

    /// Component responsible to process an array of `[ListChange<Item>]`'s and apply those changes to a view.
    private lazy var listChangeUpdater: ListChangeUpdater = CollectionViewListChangeUpdater(
        collectionView: collectionView
    )

    /// A component responsible to handle when to load new messages.
    private lazy var viewPaginationHandler: ViewPaginationHandling = {
        ScrollViewPaginationHandler(scrollView: collectionView)
    }()

    private var isPaginatingMessages: Bool = false

    override open func setUpLayout() {
        super.setUpLayout()

        view.embed(emptyView)
        emptyView.isHidden = true
        emptyView.actionButton.removeFromSuperview()
        emptyView.titleLabel.isHidden = true
    }

    override open func setUp() {
        collectionView.register(
            components.channelCell.self,
            forCellWithReuseIdentifier: collectionViewCellReuseIdentifier
        )

        collectionView.register(
            components.channelCellSeparator,
            forSupplementaryViewOfKind: ListCollectionViewLayout.separatorKind,
            withReuseIdentifier: separatorReuseIdentifier
        )

        collectionView.dataSource = self
        collectionView.delegate = self

        viewPaginationHandler.bottomThreshold = 800
        viewPaginationHandler.onNewBottomPage = { [weak self] in
            self?.loadMoreMessages()
        }

        messageSearchController.delegate = self
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        emptyView.iconView.image = appearance.images.emptySearch
    }

    public func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text, !text.isEmpty, text != currentSearchText else {
            return
        }

        currentSearchText = text

        debouncer.execute { [weak self] in
            self?.messageSearchController.search(text: text)
        }
    }

    override open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        messageSearchController.messages.count
    }

    override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(with: ChatChannelListCollectionViewCell.self, for: indexPath)
        guard let message = messageSearchController.messages[safe: indexPath.item],
              let cid = message.cid,
              let channel = messageSearchController.dataStore.channel(cid: cid) else {
            return cell
        }

        cell.components = components
        cell.itemView.content = .init(
            channel: channel,
            currentUserId: messageSearchController.client.currentUserId,
            searchedMessage: message
        )
        
        cell.swipeableView.delegate = self
        cell.swipeableView.indexPath = { [weak cell, weak self] in
            guard let cell = cell else { return nil }
            return self?.collectionView.indexPath(for: cell)
        }

        return cell
    }

    override open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defer {
            collectionView.deselectItem(at: indexPath, animated: true)
        }

        guard let message = messageSearchController.messages[safe: indexPath.item],
              let cid = message.cid,
              let channel = messageSearchController.dataStore.channel(cid: cid) else {
            return
        }

        didSelectMessage?(channel, message)
    }

    open func loadMoreMessages() {
        guard !isPaginatingMessages else {
            return
        }
        isPaginatingMessages = true

        messageSearchController.loadNextMessages { [weak self] _ in
            self?.isPaginatingMessages = false
        }
    }

    override open func controller(_ controller: DataController, didChangeState state: DataController.State) {
        switch state {
        case .initialized, .localDataFetched:
            if messageSearchController.messages.isEmpty {
                loadingIndicator.startAnimating()
            } else {
                loadingIndicator.stopAnimating()
            }
        case .remoteDataFetched:
            loadingIndicator.stopAnimating()
            emptyView.subtitleLabel.text = L10n.ChannelList.Search.Empty.subtitle("\"\(currentSearchText)\"")
            emptyView.isHidden = !messageSearchController.messages.isEmpty
        default:
            loadingIndicator.stopAnimating()
        }
    }

    open func controller(_ controller: ChatMessageSearchController, didChangeMessages changes: [ListChange<ChatMessage>]) {
        listChangeUpdater.performUpdate(with: changes)
    }

    deinit {
        debouncer.invalidate()
    }
}
