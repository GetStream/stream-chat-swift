// LINK: https://getstream.io/chat/docs/ios-swift/ios_push_notifications/?preview=1&language=swift#remove-a-user-device

import StreamChat
import UIKit

private var chatClient: ChatClient!

func snippet_ux_notifications_remove_user_device() {
    let deviceId = chatClient.currentUserController().currentUser!.devices.last!.id
    
    chatClient.currentUserController().removeDevice(id: deviceId)
    // or
    chatClient.currentUserController().removeDevice(id: deviceId) { error in
        if let error = error {
            // handle error
            print(error)
        }
    }
}
