//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

private var chatClient: ChatClient!

func snippet_ux_notifications_add_user_device() {
    // > import UIKit
    // > import StreamChat
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        chatClient.currentUserController().addDevice(token: deviceToken)
        // or
        chatClient.currentUserController().addDevice(token: deviceToken) { error in
            if let error = error {
                // handle error
                print(error)
            }
        }
    }
}
