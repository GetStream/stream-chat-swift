//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/disabling-channels/

import StreamChat

@MainActor struct Snippets_03_07_12_Disabling {
    var chatClient: ChatClient!

    func excludeDisabledChannels() {
        let controller = chatClient.channelListController(
          query: ChannelListQuery(
            filter: .equal(.disabled, to: false)
          )
        )
        controller.synchronize { error in
          if let error = error {
            // handle error
            print(error)
          } else {
            print(controller.channels)
          }
        }
    }
}
