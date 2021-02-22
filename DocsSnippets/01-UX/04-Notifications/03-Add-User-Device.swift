// LINK: https://getstream.io/chat/docs/ios-swift/ios_push_notifications/?preview=1&language=swift#add-a-user-device

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
