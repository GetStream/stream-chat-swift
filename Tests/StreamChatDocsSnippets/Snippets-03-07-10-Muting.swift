//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/muting-channels/

import StreamChat

@MainActor struct Snippets_03_07_10_Muting {
    var chatClient: ChatClient!

    func muteAChannel() {
        let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        // mute channel
        controller.muteChannel { error in
          if let error = error {
            // handle error
            print(error)
          }
        }

        // mute channel for 2 weeks (expiration in milliseconds)
        controller.muteChannel(expiration: 14 * 24 * 60 * 60 * 1000) { error in
          if let error = error {
            // handle error
            print(error)
          }
        }
    }

    func muteAChannelAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        // mute channel
        try await chat.mute()

        // mute channel for 2 weeks (expiration in milliseconds)
        try await chat.mute(expiration: 14 * 24 * 60 * 60 * 1000)
    }

    func queryMutedChannels() async throws {
        // Controllers

        let controller = chatClient.channelListController(
          query: .init(
            filter: .equal(.muted, to: true)
          )
        )
        controller.synchronize { error in
          print(error ?? controller.channels)
        }

        // State layer (async-await)

        let channelList = chatClient.makeChannelList(
          with: ChannelListQuery(
            filter: .equal(.muted, to: true)
          )
        )
        try await channelList.get()
        let mutedChannels = channelList.state.channels
        suppressUnusedWarning(mutedChannels)
    }

    func removeAChannelMute() {
        let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        // unmute channel
        controller.unmuteChannel { error in
          if let error = error {
            // handle error
            print(error)
          }
        }
    }

    func removeAChannelMuteAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        // unmute channel
        try await chat.unmute()
    }
}
