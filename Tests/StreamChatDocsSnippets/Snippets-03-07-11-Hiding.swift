//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/hiding-channels/

import StreamChat

@MainActor struct Snippets_03_07_11_Hiding {
    var chatClient: ChatClient!

    func hideAChannel() {
        let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        // hide channel
        controller.hideChannel { error in
          if let error = error {
            // handle error
            print(error)
          }
        }

        // show channel
        controller.showChannel { error in
          if let error = error {
            // handle error
            print(error)
          }
        }

        // hide channel and clear message history
        controller.hideChannel(clearHistory: true) { error in
          if let error = error {
            // handle error
            print(error)
          }
        }
    }

    func hideAChannelAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        // hide channel
        try await chat.hide()

        // show channel
        try await chat.show()

        // hide channel and clear message history
        try await chat.hide(clearHistory: true)
    }
}
