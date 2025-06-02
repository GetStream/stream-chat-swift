//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import SwiftUI
import UIKit

class DemoAppTabBarController: UITabBarController, CurrentChatUserControllerDelegate {
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
        unreadCount = currentUserController.unreadCount

        tabBar.backgroundColor = Appearance.default.colorPalette.background
        tabBar.isTranslucent = true

        channelListVC.tabBarItem.title = "Channels"
        channelListVC.tabBarItem.image = UIImage(systemName: "message")
        channelListVC.tabBarItem.badgeColor = .red

        threadListVC.tabBarItem.title = "Threads"
        threadListVC.tabBarItem.image = UIImage(systemName: "text.bubble")
        threadListVC.tabBarItem.badgeColor = .red

        draftListVC.tabBarItem.title = "Drafts"
        draftListVC.tabBarItem.image = UIImage(systemName: "bubble.and.pencil")

        viewControllers = [channelListVC, threadListVC, draftListVC]
    }

    // MARK: - Shake Detection
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            presentLogsView()
        }
    }
    
    private func presentLogsView() {
        // Check if LogsView is already presented
        if presentedViewController != nil {
            return
        }
        
        if #available(iOS 16.0, *) {
            let logsView = LogListView()
            let hostingController = UIHostingController(rootView: logsView)
            hostingController.modalPresentationStyle = .pageSheet
            
            // Configure the sheet presentation
            if let sheet = hostingController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
            }
            
            present(hostingController, animated: true)
        } else {
            // For iOS versions below 16.0, show a simple alert
            let alert = UIAlertController(
                title: "Logs Unavailable",
                message: "Logs view requires iOS 16.0 or later",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUserUnreadCount: UnreadCount) {
        let unreadCount = didChangeCurrentUserUnreadCount
        self.unreadCount = unreadCount
        let totalUnreadBadge = unreadCount.channels + unreadCount.threads
        UIApplication.shared.applicationIconBadgeNumber = totalUnreadBadge
    }
}
