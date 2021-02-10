//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

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
