//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import StreamChatUI
import UIKit

class DemoAppTabBarController: UITabBarController, CurrentChatUserControllerDelegate {
    private var locationProvider = LocationProvider.shared
    private var locationUpdatesPublisher = PassthroughSubject<LocationAttachmentInfo, Never>()
    private var cancellables = Set<AnyCancellable>()

    let channelListVC: UIViewController
    let threadListVC: UIViewController
    let currentUserController: CurrentChatUserController

    init(
        channelListVC: UIViewController,
        threadListVC: UIViewController,
        currentUserController: CurrentChatUserController
    ) {
        self.channelListVC = channelListVC
        self.threadListVC = threadListVC
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
        unreadCount = currentUserController.unreadCount

        tabBar.backgroundColor = Appearance.default.colorPalette.background
        tabBar.isTranslucent = true

        channelListVC.tabBarItem.title = "Channels"
        channelListVC.tabBarItem.image = UIImage(systemName: "message")
        channelListVC.tabBarItem.badgeColor = .red

        threadListVC.tabBarItem.title = "Threads"
        threadListVC.tabBarItem.image = UIImage(systemName: "text.bubble")
        threadListVC.tabBarItem.badgeColor = .red

        viewControllers = [channelListVC, threadListVC]

        locationProvider.didUpdateLocation = { [weak self] location in
            self?.locationUpdatesPublisher.send(LocationAttachmentInfo(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ))
        }
        locationUpdatesPublisher
            .throttle(for: 5, scheduler: DispatchQueue.global(), latest: true)
            .sink { [weak self] newLocation in
                print("Sending new location to the server:", newLocation)
                self?.currentUserController.updateLiveLocation(newLocation)
            }
            .store(in: &cancellables)
    }

    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUserUnreadCount: UnreadCount) {
        let unreadCount = didChangeCurrentUserUnreadCount
        self.unreadCount = unreadCount
        let totalUnreadBadge = unreadCount.channels + unreadCount.threads
        UIApplication.shared.applicationIconBadgeNumber = totalUnreadBadge
    }

    func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeActiveLiveLocationMessages messages: [ChatMessage]
    ) {
        /// If there are no active live location messages, we stop monitoring the location.
        if messages.isEmpty {
            locationProvider.stopMonitoringLocation()
            /// If there are active live location messages, we start monitoring the location.
        } else if !locationProvider.isMonitoringLocation {
            locationProvider.startMonitoringLocation()
        }
    }
}
