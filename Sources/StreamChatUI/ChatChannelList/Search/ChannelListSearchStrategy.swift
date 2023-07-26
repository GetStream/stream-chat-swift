//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The component responsible for creating the `UISearchController` of the Channel List.
public protocol ChannelListSearchFactory {
    func makeSearchController(with channelListVC: ChatChannelListVC) -> UISearchController?
}

/// The channel list search strategy. It is possible to search by messages or channels, or provide your custom strategy.
public struct ChannelListSearchStrategy: ChannelListSearchFactory {
    public var name: String
    public var searchVC: (UIViewController & UISearchResultsUpdating).Type

    internal init(searchVC: (UIViewController & UISearchResultsUpdating).Type, name: String) {
        self.searchVC = searchVC
        self.name = name
    }

    public static let messages: Self = .messages(ChatMessageSearchVC.self)
    public static let channels: Self = .channels(ChatChannelSearchVC.self)

    public static func messages(_ searchVC: ChatMessageSearchVC.Type) -> Self {
        .init(searchVC: searchVC, name: "messages")
    }

    public static func channels(_ searchVC: ChatChannelSearchVC.Type) -> Self {
        .init(searchVC: searchVC, name: "channels")
    }

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
