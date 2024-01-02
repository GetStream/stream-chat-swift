//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = SplashViewController(
            userInfo: .init(id: "sagar"),
            token: .development(userId: "sagar")
        ) { [unowned window] in
            window.rootViewController = UINavigationController(
                rootViewController: YTLiveVideoViewController()
            )
        }
        window.makeKeyAndVisible()
        self.window = window

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .moviePlayback)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }

        return true
    }
}
