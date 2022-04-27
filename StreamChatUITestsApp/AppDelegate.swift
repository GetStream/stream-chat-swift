//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        disableAnimations()
        setupUI()
        return true
    }

    func setupUI() {
        // Empty root view controller
        let rootViewController = ViewController()

        // Embed in navigation controller
        window = UIWindow()
        window?.rootViewController = UINavigationController(rootViewController: rootViewController)
        window?.makeKeyAndVisible()
    }
    
    func disableAnimations() {
        UIApplication.shared.keyWindow?.layer.speed = 2
        UIView.setAnimationsEnabled(false)
    }

}
