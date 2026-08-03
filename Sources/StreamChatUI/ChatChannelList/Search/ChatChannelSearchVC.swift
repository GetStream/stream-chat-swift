//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view controller responsible to search channels.
/// It implements the required functions of the `ChatChannelListSearchVC` abstract class.
@available(iOSApplicationExtension, unavailable)
open class ChatChannelSearchVC: ChatChannelListSearchVC {
    /// The `ChatChannelSearchController` instance used to perform debounced channel searches.
    public lazy var channelSearchController: ChatChannelSearchController = {
        let searchController = controller.client.channelSearchController()
        searchController.didCreateChannelListController = { [weak self] listController in
            self?.replaceChannelListController(listController)
        }
        return searchController
    }()

    /// The closure that is triggered whenever a channel is selected from the search result.
    public var didSelectChannel: (@MainActor (ChatChannel) -> Void)?

    // MARK: - ChatChannelListSearchVC Abstract Implementations

    override open var hasEmptyResults: Bool {
        controller.channels.isEmpty
    }

    override open func loadSearchResults(with text: String) {
        channelSearchController.search(text: text)
    }

    override open func loadMoreSearchResults() {
        loadMoreChannels()
    }

    override open func cancelSearch() {
        channelSearchController.clearResults()
    }

    // MARK: - Collection View Implementations

    override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
        guard let channelListCell = cell as? ChatChannelListCollectionViewCell,
              let channel = channelListCell.itemView.content?.channel else {
            return cell
        }

        channelListCell.itemView.content = .init(
            channel: channel,
            currentUserId: controller.client.currentUserId,
            searchResult: .init(text: currentSearchText, message: nil)
        )

        return channelListCell
    }

    override open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defer {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
        guard let channel = channels[safe: indexPath.row] else { return }
        didSelectChannel?(channel)
    }
}
