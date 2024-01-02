//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
import UIKit

final class DemoChatChannelListVC: ChatChannelListVC, EventsControllerDelegate {
    /// The `UIButton` instance used for navigating to new channel screen creation.
    lazy var createChannelButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "plus.message")!, for: .normal)
        return button
    }()

    lazy var filterChannelsButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "slider.horizontal.3")!, for: .normal)
        return button
    }()

    private lazy var eventsController = controller.client.eventsController()
    private lazy var connectionController = controller.client.connectionController()
    private lazy var connectionDelegate = BannerShowingConnectionDelegate(
        showUnder: navigationController!.navigationBar
    )

    var highlightSelectedChannel: Bool { splitViewController?.isCollapsed == false }
    var selectedChannel: ChatChannel?

    var currentUserId: UserId {
        controller.client.currentUserId!
    }

    var initialQuery: ChannelListQuery!

    lazy var hiddenChannelsQuery: ChannelListQuery = .init(filter: .and([
        .containMembers(userIds: [currentUserId]),
        .equal(.hidden, to: true)
    ]))

    lazy var mutedChannelsQuery: ChannelListQuery = .init(filter: .and([
        .containMembers(userIds: [currentUserId]),
        .equal(.muted, to: true)
    ]))

    lazy var coolChannelsQuery: ChannelListQuery = .init(filter: .and([
        .containMembers(userIds: [currentUserId]),
        .equal("is_cool", to: true)
    ]))

    var demoRouter: DemoChatChannelListRouter? {
        router as? DemoChatChannelListRouter
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Channels"

        initialQuery = controller.query

        eventsController.delegate = self
        connectionController.delegate = connectionDelegate

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: filterChannelsButton),
            UIBarButtonItem(customView: createChannelButton)
        ]
        createChannelButton.addTarget(self, action: #selector(didTapCreateNewChannel), for: .touchUpInside)
        filterChannelsButton.addTarget(self, action: #selector(didTapFilterChannelsButton), for: .touchUpInside)

        emptyView.actionButtonPressed = { [weak self] in
            guard let self = self else { return }
            self.didTapCreateNewChannel(self)
        }
    }

    @objc private func didTapCreateNewChannel(_ sender: Any) {
        demoRouter?.showCreateNewChannelFlow()
    }

    @objc private func didTapFilterChannelsButton(_ sender: Any) {
        let defaultChannelsAction = UIAlertAction(
            title: "Initial Channels",
            style: .default,
            handler: { [weak self] _ in
                self?.title = "Channels"
                self?.setInitialChannelsQuery()
            }
        )

        let hiddenChannelsAction = UIAlertAction(
            title: "Hidden Channels",
            style: .default,
            handler: { [weak self] _ in
                self?.title = "Hidden Channels"
                self?.setHiddenChannelsQuery()
            }
        )

        let coolChannelsAction = UIAlertAction(
            title: "Cool Channels",
            style: .default,
            handler: { [weak self] _ in
                self?.title = "Cool Channels"
                self?.setCoolChannelsQuery()
            }
        )

        let mutedChannelsAction = UIAlertAction(
            title: "Muted Channels",
            style: .default,
            handler: { [weak self] _ in
                self?.title = "Muted Channels"
                self?.setMutedChannelsQuery()
            }
        )

        presentAlert(
            title: "Filter Channels",
            actions: [defaultChannelsAction, hiddenChannelsAction, mutedChannelsAction, coolChannelsAction],
            preferredStyle: .actionSheet,
            sourceView: filterChannelsButton
        )
    }

    func setHiddenChannelsQuery() {
        replaceQuery(hiddenChannelsQuery)
    }

    func setMutedChannelsQuery() {
        replaceQuery(mutedChannelsQuery)
    }

    func setCoolChannelsQuery() {
        let controller = self.controller.client.channelListController(
            query: coolChannelsQuery,
            filter: { channel in
                channel.extraData["is_cool"]?.boolValue ?? false
            }
        )
        replaceChannelListController(controller)
    }

    func setInitialChannelsQuery() {
        replaceQuery(initialQuery)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let channel = controller.channels[indexPath.row]
        selectedChannel = controller.channels[indexPath.row]
        router.showChannel(for: channel.cid)
    }

    override func controller(_ controller: DataController, didChangeState state: DataController.State) {
        super.controller(controller, didChangeState: state)

        if highlightSelectedChannel && (state == .remoteDataFetched || state == .localDataFetched) && selectedChannel == nil {
            guard let channel = self.controller.channels.first else { return }

            router.showChannel(for: channel.cid)

            selectedChannel = channel
        }
    }

    override func controller(_ controller: ChatChannelListController, didChangeChannels changes: [ListChange<ChatChannel>]) {
        super.controller(controller, didChangeChannels: changes)

        guard highlightSelectedChannel else { return }
        guard let selectedChannel = selectedChannel else { return }
        guard let selectedChannelRow = controller.channels.firstIndex(of: selectedChannel) else {
            return
        }

        let selectedItemIndexPath = IndexPath(row: selectedChannelRow, section: 0)

        collectionView.selectItem(
            at: selectedItemIndexPath,
            animated: false,
            scrollPosition: .centeredHorizontally
        )
    }

    func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        if let newMessageEvent = event as? MessageNewEvent {
            // This is a DemoApp integration test to make sure there are no deadlocks when
            // accessing CoreDataLazy properties from the EventsController.delegate
            _ = newMessageEvent.message.author
        }
    }
}
