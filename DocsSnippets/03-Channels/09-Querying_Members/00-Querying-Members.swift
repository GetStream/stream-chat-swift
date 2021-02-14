// LINK: https://getstream.io/chat/docs/ios-swift/query_users/?preview=1&language=swift

import StreamChat

private var chatClient: ChatClient!

func snippet_channels_deleting_muting_channels_channel_remove_channel_mute() {
    // > import StreamChat

    // query by user.name
    let controller = chatClient.memberListController(
        query: .init(cid: .init(type: .messaging, id: "general"), filter: .equal(.name, to: "tommaso"))
    )

    controller.synchronize { error in
        // handle error / access members
        print(error ?? controller.members)
    }

    // query members with name containing tom
    let controller1 = chatClient.memberListController(
        query: .init(cid: .init(type: .messaging, id: "general"), filter: .query(.name, text: "tom"))
    )

    controller1.synchronize { error in
        // handle error / access members
        print(error ?? controller1.members)
    }

    // autocomplete members by user name
    let controller2 = chatClient.memberListController(
        query: .init(cid: .init(type: .messaging, id: "general"), filter: .autocomplete(.name, text: "tom"))
    )

    controller2.synchronize { error in
        // handle error / access members
        print(error ?? controller2.members)
    }

    // query member by id
    let controller3 = chatClient.memberListController(
        query: .init(cid: .init(type: .messaging, id: "general"), filter: .equal(.id, to: "tommaso"))
    )

    controller3.synchronize { error in
        // handle error / access members
        print(error ?? controller3.members)
    }

    // query multiple members by id
    let controller4 = chatClient.memberListController(
        query: .init(cid: .init(type: .messaging, id: "general"), filter: .in(.id, values: ["tommaso", "thierry"]))
    )

    controller4.synchronize { error in
        // handle error / access members
        print(error ?? controller4.members)
    }

    // query channel moderators
    let controller5 = chatClient.memberListController(
        query: .init(cid: .init(type: .messaging, id: "general"), filter: .equal(.isModerator, to: true))
    )

    controller5.synchronize { error in
        // handle error / access members
        print(error ?? controller5.members)
    }

    // query for banned members in channel
    let controller6 = chatClient.memberListController(
        query: .init(cid: .init(type: .messaging, id: "general"), filter: .equal(.isBanned, to: true))
    )

    controller6.synchronize { error in
        // handle error / access members
        print(error ?? controller6.members)
    }

    // query members with pending invites
    let controller7 = chatClient.memberListController(
        query: .init(cid: .init(type: .messaging, id: "general"), filter: .equal("invite", to: "pending"))
    )

    controller7.synchronize { error in
        // handle error / access members
        print(error ?? controller7.members)
    }

    // query all the members
    let controller8 = chatClient.memberListController(
        query: .init(cid: .init(type: .messaging, id: "general"), filter: .none)
    )

    controller8.synchronize { error in
        // handle error / access members
        print(error ?? controller8.members)
    }

    // paginate channel members
    controller8.loadNextMembers(limit: 10) { error in
        // handle error / access members
        print(error ?? controller8.members)
    }

    // order results by member created at descending
    let controller9 = chatClient.memberListController(
        query: .init(cid: .init(type: .messaging, id: "general"), sort: [.init(key: .createdAt, isAscending: false)])
    )

    controller9.synchronize { error in
        // handle error / access members
        print(error ?? controller9.members)
    }
}
