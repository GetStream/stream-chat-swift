//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit
import UserNotifications

class DemoAppTabBarController: UITabBarController, CurrentChatUserControllerDelegate, EventsControllerDelegate {
    let channelListVC: UIViewController
    let threadListVC: UIViewController
    let draftListVC: UIViewController
    let reminderListVC: UIViewController
    let currentUserController: CurrentChatUserController
    
    // Events controller for listening to chat events
    private var eventsController: EventsController!
    
    // User notification center for displaying local notifications
    private let notificationCenter = UNUserNotificationCenter.current()

    init(
        channelListVC: UIViewController,
        threadListVC: UIViewController,
        draftListVC: UIViewController,
        reminderListVC: UIViewController,
        currentUserController: CurrentChatUserController
    ) {
        self.channelListVC = channelListVC
        self.threadListVC = threadListVC
        self.draftListVC = draftListVC
        self.reminderListVC = reminderListVC
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
        
        // Initialize events controller
        setupEventsController()

        // Update reminders badge if the feature is enabled.
        if AppConfig.shared.demoAppConfig.isRemindersEnabled {
            updateRemindersBadge()
        }

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
        
        reminderListVC.tabBarItem.title = "Reminders"
        reminderListVC.tabBarItem.image = UIImage(systemName: "bell")

        // Only show reminders tab if the feature is enabled
        if AppConfig.shared.demoAppConfig.isRemindersEnabled {
            viewControllers = [channelListVC, threadListVC, draftListVC, reminderListVC]
        } else {
            viewControllers = [channelListVC, threadListVC, draftListVC]
        }
    }
    
    // MARK: - Events Controller Setup
    
    private func setupEventsController() {
        eventsController = currentUserController.client.eventsController()
        eventsController.delegate = self
    }
    
    // MARK: - EventsControllerDelegate
    
    func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        if AppConfig.shared.demoAppConfig.isRemindersEnabled,
           let reminderDueEvent = event as? ReminderDueEvent {
            handleReminderDueEvent(reminderDueEvent)
        }
    }
    
    // MARK: - Handle Reminder Due Event
    
    private func handleReminderDueEvent(_ event: ReminderDueEvent) {
        let messageText = event.reminder.message.text
        let content = UNMutableNotificationContent()
        content.title = "Reminder due"
        content.body = messageText
        content.sound = .default

        let identifier = "reminder-\(event.messageId)-\(Date().timeIntervalSince1970)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        notificationCenter.add(request)
    }

    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUserUnreadCount: UnreadCount) {
        let unreadCount = didChangeCurrentUserUnreadCount
        self.unreadCount = unreadCount
        let totalUnreadBadge = unreadCount.channels + unreadCount.threads
        UIApplication.shared.applicationIconBadgeNumber = totalUnreadBadge
    }

    func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeMessageReminders messageReminders: [MessageReminder]
    ) {
        updateRemindersBadge()
    }

    private func updateRemindersBadge() {
        let reminders = currentUserController.messageReminders
        reminderListVC.tabBarItem.badgeValue = reminders.isEmpty ? nil : "\(reminders.count)"
    }
}
