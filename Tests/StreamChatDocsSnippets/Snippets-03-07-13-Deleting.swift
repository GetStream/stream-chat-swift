//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/channel-delete/

import StreamChat

@MainActor struct Snippets_03_07_13_Deleting {
    var chatClient: ChatClient!

    func deletingAChannel() {
        let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        controller.deleteChannel { error in
          if let error = error {
            // handle error
            print(error)
          }
        }
    }

    func deletingAChannelAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        try await chat.delete()
    }
}
