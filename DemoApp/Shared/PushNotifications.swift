//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit
import UserNotifications

final class PushNotifications: NSObject {
    var center: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }

    var authorizationOptions: UNAuthorizationOptions {
        [.alert, .sound, .badge]
    }

    private var onNotificationResponse: ((UNNotificationResponse) -> Void)?

    func listenToNotificationsResponse(with onNotificationResponse: @escaping (UNNotificationResponse) -> Void) {
        center.delegate = self
        self.onNotificationResponse = onNotificationResponse
    }

    func registerForPushNotifications() {
        center.requestAuthorization(options: authorizationOptions) { [weak self] granted, _ in
            log.debug("Permission granted: \(granted)")
            self?.getNotificationSettings()
        }
    }

    private func getNotificationSettings() {
        center.getNotificationSettings { settings in
            log.debug("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}

// MARK: UNUserNotificationCenter Delegate methods

extension PushNotifications: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.badge, .banner])
        } else {
            completionHandler([.badge])
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        onNotificationResponse?(response)
        completionHandler()
    }
}
