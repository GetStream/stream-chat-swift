//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit
import UserNotifications
import StreamChat

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private let pushNotifications = PushNotifications()

    var window: UIWindow?
    private var coordinator: DemoAppCoordinator!

    // Stream Chat
    var chat: StreamChatWrapper {
        StreamChatWrapper.shared
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        disableAnimations()
        setupUI()
        registerForPushNotifications()
        return true
    }

    func setupUI() {
        let window = UIWindow()
        window.makeKeyAndVisible()
        self.window = window
        makeCoordinator(in: window)
    }

    func makeCoordinator(in window: UIWindow) {
        // Hook on registration for push notifications.
        // This closure is called once the chat user is connected.
        chat.onRemotePushRegistration = { [weak self] in
            self?.pushNotifications.registerForPushNotifications()
        }

        // Create coordinator for this demo app
        coordinator = DemoAppCoordinator(
            window: window,
            chat: chat,
            pushNotifications: pushNotifications
        )
        coordinator.start { error in
            if let error = error {
                log.error("Error starting app \(error)")
            } else {
                log.debug("Successfully started app")
            }
        }
    }

    func disableAnimations() {
        UIApplication.shared.keyWindow?.layer.speed = 2
        UIView.setAnimationsEnabled(false)
    }

    func registerForPushNotifications() {
        if #available(iOS 14, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                guard granted else { return }
                self?.getNotificationSettings()
            }
        }
    }

    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register: \(error)")
    }
}
