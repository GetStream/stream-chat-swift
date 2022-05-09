//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Sentry
import StreamChat
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        #if RELEASE
        // We're tracking Crash Reports / Issues from the Demo App to keep improving the SDK
        SentrySDK.start { options in
            options.dsn = "https://75b1074a38704dc0923d9de56fe1e1d4@o389650.ingest.sentry.io/6379288"
            options.tracesSampleRate = 1.0
        }
        #endif
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        guard let currentUserId = ChatClient.shared.currentUserId else {
            log.warning("cannot add the device without connecting as user first, did you call connectUser")
            return
        }

        ChatClient.shared.currentUserController().addDevice(.apn(token: deviceToken)) { error in
            if let error = error {
                log.error("adding a device failed with an error \(error)")
                return
            }
            UserDefaults(suiteName: applicationGroupIdentifier)?
                .set(currentUserId, forKey: currentUserIdRegisteredForPush)
        }
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
