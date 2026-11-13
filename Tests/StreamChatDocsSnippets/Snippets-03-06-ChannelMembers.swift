//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/channel-members/

import Foundation
import StreamChat

@MainActor struct Snippets_03_06_ChannelMembers {
    var chatClient: ChatClient!
    var channelController: ChatChannelController!
    var someUserId: UserId!
    var someChannelId: ChannelId!

    func addingMembers() {
        let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        controller.addMembers(userIds: ["thierry", "josh"])
    }

    func addingMembersAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        try await chat.addMembers(["thierry", "josh"])
    }

    func addingMembers2() throws {
        let channelId = ChannelId(type: .messaging, id: "general")
        let channelController = try chatClient.channelController(
          createChannelWithId: channelId,
          members: ["thierry", "tommaso"]
        )
        channelController.synchronize { error in
          if let error = error {
            print(error)
          }
        }
    }

    func removingMembers() {
        let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        controller.removeMembers(userIds: ["tommaso"])
    }

    func removingMembersAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        try await chat.removeMembers(["tommaso"])
    }

    func leavingAChannel() {
        channelController.removeMembers(userIds: ["john"]) { error in
          // …
        }
    }

    func hideHistory() {
        let channelController = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        channelController.addMembers(
          userIds: ["thierry"],
          hideHistory: true
        ) { error in
          // …
        }
    }

    func hideHistoryAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        try await chat.addMembers(["thierry"], hideHistory: true)
    }

    func hideHistoryBeforeASpecificDate() {
        let channelController = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        channelController.addMembers(
          userIds: ["thierry"],
          hideHistoryBefore: cutoff
        ) { error in
          // …
        }
    }

    func hideHistoryBeforeASpecificDateAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        try await chat.addMembers(["thierry"], hideHistoryBefore: cutoff)
    }

    func systemMessageParameter() {
        let channelController = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        channelController.addMembers(
          userIds: ["tommaso"],
          message: "Tommaso joined the channel"
        ) { error in
          // …
        }
    }

    func systemMessageParameterAsync() async throws {
        let chat = chatClient.makeChat(for: .init(type: .messaging, id: "general"))

        try await chat.addMembers(["tommaso"], systemMessage: "Tommaso joined the channel")
    }

    func addingCustomData() {
        channelController.addMembers([
        	MemberInfo(userId: "userid1", extraData: ["key1": .string("value1")]),
        	MemberInfo(userId: "userid2", extraData: ["key2": .string("value2")]),
        	MemberInfo(userId: "userid3", extraData: ["key3": .string("value3")])
        ])
    }

    func updatingMemberData() {
        // Set some fields
        let memberController = chatClient.memberController(
        	userId: someUserId,
        	in: someChannelId
        )
        memberController.partialUpdate(extraData: [
        	"key1": .string("value1"),
        	"key2": .string("value2")
        ])

        // Unset some fields
        memberController.partialUpdate(extraData: nil, unsetProperties: ["key1", "key2"])

        // Set and unset in the same call
        memberController.partialUpdate(
        	extraData: [
        		"key1": .string("value1"),
        		"key2": .string("value2"),
        	],
        	unsetProperties: ["key3"]
        )
    }
}
