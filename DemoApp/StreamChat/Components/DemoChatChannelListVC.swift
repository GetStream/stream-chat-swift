//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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

    lazy var hiddenChannelsButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "archivebox")!, for: .normal)
        return button
    }()

    private lazy var eventsController = controller.client.eventsController()
    private lazy var connectionController = controller.client.connectionController()
    private lazy var connectionDelegate = BannerShowingConnectionDelegate(
        showUnder: navigationController!.navigationBar
    )

    var demoRouter: DemoChatChannelListRouter? {
        router as? DemoChatChannelListRouter
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        eventsController.delegate = self
        connectionController.delegate = connectionDelegate

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: hiddenChannelsButton),
            UIBarButtonItem(customView: createChannelButton)
        ]
        createChannelButton.addTarget(self, action: #selector(didTapCreateNewChannel), for: .touchUpInside)
        hiddenChannelsButton.addTarget(self, action: #selector(didTapHiddenChannelsButton), for: .touchUpInside)
    }

    @objc private func didTapCreateNewChannel(_ sender: Any) {
        demoRouter?.showCreateNewChannelFlow()
    }

    @objc private func didTapHiddenChannelsButton(_ sender: Any) {
        demoRouter?.showHiddenChannels()
    }

    var highlightSelectedChannel: Bool { splitViewController?.isCollapsed == false }
    var selectedChannel: ChatChannel?

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
