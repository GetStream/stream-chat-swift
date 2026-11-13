//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/channel-invites/

import StreamChat

@MainActor struct Snippets_03_07_16_ChannelInvites {
    var chatClient: ChatClient!

    func inviteUsers() {
        let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        controller.inviteMembers(userIds: ["thierry"])
    }

    func inviteUsersAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        try await chat.inviteMembers(["thierry"])
    }

    func acceptAnInvite() {
        let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        controller.acceptInvite(message: "Nick joined this channel!")
    }

    func acceptAnInviteAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        try await chat.acceptInvite(with: "Nick joined this channel!")
    }

    func rejectAnInvite() {
        let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        controller.rejectInvite()
    }

    func rejectAnInviteAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        try await chat.rejectInvite()
    }

    func queryAcceptedInvites() {
        let controller = chatClient.channelListController(
          query: .init(
            filter: .equal(.invite, to: .accepted)
          )
        )

        controller.synchronize { error in
          if let error = error {
            // handle error
            print(error)
          } else {
            // access channels
            print(controller.channels)

            // load more if needed
            controller.loadNextChannels(limit: 10) { _ in
              // handle error / access channels
            }
          }
        }
    }

    func queryRejectedInvites() {
        let controller = chatClient.channelListController(
          query: .init(
            filter: .equal(.invite, to: .rejected)
          )
        )

        controller.synchronize { error in
          if let error = error {
            // handle error
            print(error)
          } else {
            // access channels
            print(controller.channels)

            // load more if needed
            controller.loadNextChannels(limit: 10) { _ in
              // handle error / access channels
            }
          }
        }
    }

    func queryPendingInvites() {
        let controller = chatClient.channelListController(
          query: .init(
            filter: .equal(.invite, to: .pending)
          )
        )

        controller.synchronize { error in
          if let error = error {
            // handle error
            print(error)
          } else {
            // access channels
            print(controller.channels)

            // load more if needed
            controller.loadNextChannels(limit: 10) { _ in
              // handle error / access channels
            }
          }
        }
    }
}
