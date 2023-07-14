//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view controller responsible to search channels.
open class ChatChannelSearchVC: ChatChannelListVC, UISearchResultsUpdating {
    /// The closure that is triggered whenever a channel is selected from the search result.
    public var didSelectChannel: ((ChatChannel) -> Void)?

    /// The component responsible to debounce search requests.
    public var debouncer = Debouncer(0.3, queue: .main)

    /// The current active search text.
    public var currentSearchText: String = ""

    /// A component responsible to handle when to load new channels.
    private lazy var viewPaginationHandler: ViewPaginationHandling = {
        ScrollViewPaginationHandler(scrollView: collectionView)
    }()

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
            self?.loadMoreChannels()
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        emptyView.iconView.image = appearance.images.emptySearch
    }

    open func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text, !text.isEmpty, text != currentSearchText else {
            return
        }

        currentSearchText = text

        guard let currentUserId = controller.client.currentUserId else { return }

        debouncer.execute { [weak self] in
            self?.replaceQuery(.init(
                filter: .and([
                    .autocomplete(.name, text: text),
                    .containMembers(userIds: [currentUserId])
                ])
            ))
        }
    }

    override open func controller(_ controller: DataController, didChangeState state: DataController.State) {
        switch state {
        case .initialized, .localDataFetched:
            if self.controller.channels.isEmpty {
                loadingIndicator.startAnimating()
            } else {
                loadingIndicator.stopAnimating()
            }
        case .remoteDataFetched:
            loadingIndicator.stopAnimating()
            emptyView.subtitleLabel.text = L10n.ChannelList.Search.Empty.subtitle("\"\(currentSearchText)\"")
            emptyView.isHidden = !self.controller.channels.isEmpty
        default:
            loadingIndicator.stopAnimating()
        }
    }

    override open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defer {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
        guard let channel = controller.channels[safe: indexPath.row] else { return }
        didSelectChannel?(channel)
    }

    deinit {
        debouncer.invalidate()
    }
}
