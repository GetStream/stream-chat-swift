//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view controller responsible to search channels.
/// It implements the required functions of the `ChatChannelListSearchVC` abstract class.
@available(iOSApplicationExtension, unavailable)
open class ChatChannelSearchVC: ChatChannelListSearchVC {
    /// The closure that is triggered whenever a channel is selected from the search result.
    public var didSelectChannel: ((ChatChannel) -> Void)?

    // MARK: - ChatChannelListSearchVC Abstract Implementations

    override open var hasEmptyResults: Bool {
        channels.isEmpty
    }

    override open func loadSearchResults(with text: String) {
        guard let currentUserId = controller.client.currentUserId else { return }

        replaceQuery(.init(
            filter: .and([
                .autocomplete(.name, text: text),
                .containMembers(userIds: [currentUserId])
            ])
        ))
    }

    override open func loadMoreSearchResults() {
        loadMoreChannels()
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
