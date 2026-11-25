//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/slow-mode/

import StreamChat

struct Snippets_05_10_11_SlowModeAndThrottling {
    var client: ChatClient!

    func channelSlowMode() {
        let channelController = client.channelController(for: .init(type: .messaging, id: "general"))

        channelController.enableSlowMode(cooldownDuration: 10)

        channelController.disableSlowMode()
    }

    func channelSlowMode2() {
        let channelController = client.channelController(for: .init(type: .messaging, id: "general"))

        channelController.synchronize { error in
          if error == nil {
            let cooldown = channelController.channel?.cooldownDuration
            suppressUnusedWarning(cooldown)
          }
        }
    }
}
