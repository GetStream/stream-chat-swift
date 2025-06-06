//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import StreamChatUI
import UIKit

class DemoAppTabBarController: UITabBarController, CurrentChatUserControllerDelegate {
    private var locationProvider = LocationProvider.shared

    let channelListVC: UIViewController
    let threadListVC: UIViewController
    let draftListVC: UIViewController
    let currentUserController: CurrentChatUserController

    init(
        channelListVC: UIViewController,
        threadListVC: UIViewController,
        draftListVC: UIViewController,
        currentUserController: CurrentChatUserController
    ) {
        self.channelListVC = channelListVC
        self.threadListVC = threadListVC
        self.draftListVC = draftListVC
        self.currentUserController = currentUserController
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var unreadCount: UnreadCount? {
        didSet {
            if let unreadChannelsCount = unreadCount?.channels, unreadChannelsCount > 0 {
                channelListVC.tabBarItem.badgeValue = "\(unreadChannelsCount)"
            } else {
                channelListVC.tabBarItem.badgeValue = nil
            }

            if let unreadThreadsCount = unreadCount?.threads, unreadThreadsCount > 0 {
                threadListVC.tabBarItem.badgeValue = "\(unreadThreadsCount)"
            } else {
                threadListVC.tabBarItem.badgeValue = nil
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        currentUserController.delegate = self
        currentUserController.loadActiveLiveLocationMessages()
        unreadCount = currentUserController.unreadCount

        tabBar.backgroundColor = Appearance.default.colorPalette.background
        tabBar.isTranslucent = true

        channelListVC.tabBarItem.title = "Channels"
        channelListVC.tabBarItem.image = UIImage(systemName: "message")
        channelListVC.tabBarItem.badgeColor = .red

        threadListVC.tabBarItem.title = "Threads"
        threadListVC.tabBarItem.image = UIImage(systemName: "text.bubble")
        threadListVC.tabBarItem.badgeColor = .red

        locationProvider.didUpdateLocation = { [weak self] location in
            let newLocation = LocationInfo(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            self?.currentUserController.updateLiveLocation(newLocation)
        }
        draftListVC.tabBarItem.title = "Drafts"
        draftListVC.tabBarItem.image = UIImage(systemName: "bubble.and.pencil")

        viewControllers = [channelListVC, threadListVC, draftListVC]
    }

    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUserUnreadCount: UnreadCount) {
        let unreadCount = didChangeCurrentUserUnreadCount
        self.unreadCount = unreadCount
        let totalUnreadBadge = unreadCount.channels + unreadCount.threads
        UIApplication.shared.applicationIconBadgeNumber = totalUnreadBadge
    }

    func currentUserControllerDidStartSharingLiveLocation(
        _ controller: CurrentChatUserController
    ) {
        debugPrint("[Location] Started sharing live location.")
        locationProvider.startMonitoringLocation()
    }

    func currentUserControllerDidStopSharingLiveLocation(_ controller: CurrentChatUserController) {
        debugPrint("[Location] Stopped sharing live location.")
        locationProvider.stopMonitoringLocation()
    }

    func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeActiveLiveLocationMessages messages: [ChatMessage]
    ) {
        guard !messages.isEmpty else {
            return
        }

        let locations: [String] = messages.compactMap {
            guard let location = $0.sharedLocation else {
                return nil
            }

            return "(lat:\(location.latitude), lon:\(location.longitude), endAt: \(location.endAt?.description ?? "nil"))"
        }

        debugPrint("[Location] Updated live locations to the server: \(locations)")
    }
}
