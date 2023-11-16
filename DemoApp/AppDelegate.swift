//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var chat: StreamChatWrapper {
        StreamChatWrapper.shared
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Sentry
        DemoAppConfiguration.configureSentry()

        print("===== new")
        
        for _ in 0..<9 {
            let url = Bundle.main.url(forResource: "new_format_v3", withExtension: "json")!

            do {
                let json = try Data(contentsOf: url)
                let start = Date()
                let data = try JSONDecoder.default.decode(QueryChannels_V3.self, from: json)
                let end = Date()
                let diff = end.timeIntervalSince(start)
                print("time: \(diff)")
            } catch {}
        }
        
        print("===== old")
        
        for _ in 0..<9 {
            let url = Bundle.main.url(forResource: "BigChannelListPayload", withExtension: "json")!

            do {
                let json = try Data(contentsOf: url)
                let start = Date()
                let data = try JSONDecoder.default.decode(ChannelListPayload.self, from: json)
                let end = Date()
                let diff = end.timeIntervalSince(start)
                print("time: \(diff)")
            } catch {}
        }
        
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Registers current device for push notifications on Stream backend
        chat.registerForPushNotifications(with: deviceToken)
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
