//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UINavigationController(
            rootViewController: SplashViewController { [unowned window] in
                window.rootViewController = UINavigationController(
                    rootViewController: iMessageChatChannelListViewController()
                )
            }
        )
        window.makeKeyAndVisible()
        self.window = window

        return true
    }
}
