//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIColor {
    static let streamBlue = UIColor(red: 0, green: 108.0 / 255.0, blue: 255.0 / 255.0, alpha: 1)
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private var coordinator: DemoAppCoordinator!
    var window: UIWindow?

    // Stream Chat
    var chat: StreamChatWrapper {
        StreamChatWrapper.shared
    }

    private let pushNotifications = PushNotifications()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }

        self.window = UIWindow(windowScene: scene)
        guard let window = self.window else { return }

        makeCoordinator(in: window)
        window.tintColor = .streamBlue
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

extension SceneDelegate {
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
        coordinator.start()
    }
}
