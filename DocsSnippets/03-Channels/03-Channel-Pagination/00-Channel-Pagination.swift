// LINK: https://getstream.io/chat/docs/ios-swift/channel_pagination/?preview=1&language=swift

import StreamChat

private var chatClient: ChatClient!

func snippet_channels_channel_pagination() {
    // > import StreamChat
    
    // messages

    let controller = chatClient.channelController(for: .init(type: .messaging, id: "general"))

    controller.loadNextMessages(limit: 25) { error in
        if let error = error {
            // handle error
            print(error)
        } else {
            // access messages
            print(controller.messages)
            
            controller.loadNextMessages(limit: 25) { error in
                // handle error / access messages
                print(error ?? controller.messages)
            }
        }
    }

    // members

    let memberController = chatClient.memberListController(query: .init(cid: .init(type: .messaging, id: "general")))

    memberController.loadNextMembers(limit: 25) { error in
        if let error = error {
            // handle error
            print(error)
        } else {
            // access members
            print(memberController.members)
            
            memberController.loadNextMembers(limit: 25) { error in
                // handle error / access members
                print(error ?? memberController.members)
            }
        }
    }
}
