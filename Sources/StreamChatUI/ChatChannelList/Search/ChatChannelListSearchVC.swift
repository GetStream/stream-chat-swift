//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// An abstract class responsible to handle the channel list search logic.
/// It is a subclass of the Channel List since most of the logic is reused from the original Channel List.
@available(iOSApplicationExtension, unavailable)
open class ChatChannelListSearchVC: ChatChannelListVC, UISearchResultsUpdating {
    /// The component responsible to debounce search requests.
    public var debouncer = Debouncer(0.3, queue: .main)

    /// The current active search text.
    public var currentSearchText: String = ""

    /// A component responsible to handle when to load new search results.
    private lazy var viewPaginationHandler: ViewPaginationHandling = {
        ScrollViewPaginationHandler(scrollView: collectionView)
    }()

    override open var isChatChannelListStatesEnabled: Bool {
        false
    }

    // MARK: - Lifecycle

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
            self?.loadMoreSearchResults()
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        emptyView.iconView.image = appearance.images.emptySearch
    }

    // MARK: - UISearchResultsUpdating

    open func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text, !text.isEmpty, text != currentSearchText else {
            return
        }

        currentSearchText = text

        debouncer.execute { [weak self] in
            self?.loadSearchResults(with: text)
        }
    }

    // MARK: - Required Implementations

    /// Whether the current search results are empty.
    open var hasEmptyResults: Bool {
        fatalError("This function should be implemented by a subclass.")
    }

    // swiftlint:disable unavailable_function
    /// Performs a request to fetch search results with the given text.
    ///
    /// - Parameter text: The text query inputted by the user.
    open func loadSearchResults(with text: String) {
        fatalError("This function should be implemented by a subclass.")
    }

    /// Called when a new page of search results should be performed.
    open func loadMoreSearchResults() {
        fatalError("This function should be implemented by a subclass.")
    }
    
    // swiftlint:enable unavailable_function

    // MARK: - State Handling

    override open func controller(_ controller: DataController, didChangeState state: DataController.State) {
        switch state {
        case .initialized, .localDataFetched:
            if hasEmptyResults {
                loadingIndicator.startAnimating()
            } else {
                loadingIndicator.stopAnimating()
            }
        case .remoteDataFetched:
            loadingIndicator.stopAnimating()
            emptyView.subtitleLabel.text = L10n.ChannelList.Search.Empty.subtitle("\"\(currentSearchText)\"")
            emptyView.isHidden = !hasEmptyResults
        default:
            loadingIndicator.stopAnimating()
        }
    }

    // MARK: - Deinit

    deinit {
        debouncer.invalidate()
    }
}
