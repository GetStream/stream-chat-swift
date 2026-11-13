//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/freezing-channels/

import StreamChat

@MainActor struct Snippets_03_07_14_Freezing {
    var chatClient: ChatClient!

    func freezeAChannel() {
        let channelController = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        channelController.freezeChannel()
    }

    func freezeAChannelAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        try await chat.freeze()
    }

    func unfreezeAChannel() {
        let channelController = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        channelController.unfreezeChannel()
    }

    func unfreezeAChannelAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        try await chat.unfreeze()
    }
}
