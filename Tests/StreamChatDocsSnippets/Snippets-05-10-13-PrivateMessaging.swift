//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/private-messaging/

import StreamChat

struct Snippets_05_10_13_PrivateMessaging {
    var chatClient: ChatClient!

    func sendingAMessageWithRestrictedVisibility() {
        // Get a channel controller
        let channelController = chatClient.channelController(for: ChannelId(type: .messaging, id: "ride-08467339"))

        // Send a message only visible to Jane
        channelController.createSystemMessage(
          text: "Hi Jane, your driver John will be at your location in 1 minute",
          restrictedVisibility: ["jane"]
        ) { result in
          // ...
        }
    }
}
