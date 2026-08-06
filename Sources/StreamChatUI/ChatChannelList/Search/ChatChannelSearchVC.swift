//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view controller responsible to search channels.
/// It implements the required functions of the `ChatChannelListSearchVC` abstract class.
@available(iOSApplicationExtension, unavailable)
open class ChatChannelSearchVC: ChatChannelListSearchVC, ChatChannelSearchControllerDelegate {
    /// The data of the channel search list.
    public private(set) var searchChannels: [ChatChannel] = []

    /// The `ChatChannelSearchController` instance to perform the channels search.
    public var channelSearchController: ChatChannelSearchController!

    /// The closure that is triggered whenever a channel is selected from the search result.
    public var didSelectChannel: (@MainActor (ChatChannel) -> Void)?

    private var isPaginatingChannels: Bool = false

    // MARK: - Lifecycle

    override open func setUp() {
        super.setUp()

        channelSearchController.delegate = self
    }

    // MARK: - ChatChannelListSearchVC Abstract Implementations

    override open var hasEmptyResults: Bool {
        channelSearchController.channels.isEmpty
    }

    override open func loadSearchResults(with text: String) {
        channelSearchController.search(text: text)
    }

    override open func loadMoreSearchResults() {
        guard !isPaginatingChannels else {
            return
        }
        isPaginatingChannels = true

        channelSearchController.loadNextChannels { [weak self] _ in
            self?.isPaginatingChannels = false
        }
    }

    override open func cancelSearch() {
        channelSearchController.clearResults()
    }

    // MARK: - Actions

    /// Updates the list view with new data.
    public func reloadSearchChannels() {
        let previousChannels = searchChannels
        let newChannels = Array(channelSearchController.channels)
        let stagedChangeset = StagedChangeset(source: previousChannels, target: newChannels)
        collectionView.reload(using: stagedChangeset, reconfigure: { _ in true }) { [weak self] newChannels in
            self?.searchChannels = newChannels
        }
    }

    // MARK: - Collection View Implementations

    override open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        searchChannels.count
    }

    override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(with: ChatChannelListCollectionViewCell.self, for: indexPath)
        guard let channel = searchChannels[safe: indexPath.item] else {
            return cell
        }

        cell.components = components
        cell.itemView.content = .init(
            channel: channel,
            currentUserId: channelSearchController.client.currentUserId,
            searchResult: .init(text: currentSearchText, message: nil)
        )

        return cell
    }

    override open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defer {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
        guard let channel = searchChannels[safe: indexPath.row] else { return }
        didSelectChannel?(channel)
    }

    // MARK: - ChatChannelSearchControllerDelegate

    open func controller(_ controller: ChatChannelSearchController, didChangeChannels changes: [ListChange<ChatChannel>]) {
        reloadSearchChannels()
    }
}
