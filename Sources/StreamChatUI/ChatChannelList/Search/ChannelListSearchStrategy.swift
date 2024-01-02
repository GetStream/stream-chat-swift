//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The channel list search strategy. It is possible to search by messages or channels.
public struct ChannelListSearchStrategy {
    /// The name of the strategy.
    public var name: String
    /// The type of search UI component.
    public var searchVC: UIViewController.Type

    internal init(searchVC: UIViewController.Type, name: String) {
        self.searchVC = searchVC
        self.name = name
    }

    /// The strategy to search by messages using the default UI component.
    public static let messages: Self = .messages(ChatMessageSearchVC.self)

    /// The strategy to search by channels using the default UI component.
    public static let channels: Self = .channels(ChatChannelSearchVC.self)

    /// The strategy to search by messages using a custom UI component.
    public static func messages(_ searchVC: ChatMessageSearchVC.Type) -> Self {
        .init(searchVC: searchVC, name: "messages")
    }

    /// The strategy to search by channels using a custom UI component.
    public static func channels(_ searchVC: ChatChannelSearchVC.Type) -> Self {
        .init(searchVC: searchVC, name: "channels")
    }

    /// Creates the `UISearchController` for the Channel List depending on the current search strategy.
    public func makeSearchController(
        with channelListVC: ChatChannelListVC
    ) -> UISearchController? {
        if let messageSearchVC = searchVC.init() as? ChatMessageSearchVC {
            let messageSearchController = channelListVC.controller.client.messageSearchController()
            messageSearchVC.messageSearchController = messageSearchController
            messageSearchVC.didSelectMessage = { [weak channelListVC] channel, message in
                channelListVC?.router.showChannel(for: channel.cid, at: message.id)
            }
            let searchController = UISearchController(searchResultsController: messageSearchVC)
            searchController.searchResultsUpdater = messageSearchVC
            return searchController
        }

        if let channelSearchVC = searchVC.init() as? ChatChannelSearchVC {
            channelSearchVC.controller = channelListVC.controller
            channelSearchVC.didSelectChannel = { [weak channelListVC] channel in
                channelListVC?.router.showChannel(for: channel.cid)
            }
            let searchController = UISearchController(searchResultsController: channelSearchVC)
            searchController.searchResultsUpdater = channelSearchVC
            return searchController
        }

        return nil
    }
}
