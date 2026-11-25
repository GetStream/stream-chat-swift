//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/channel-update/

import StreamChat

struct Snippets_03_03_ChannelUpdate {
    var chatClient: ChatClient!
    var channelController: ChatChannelController!

    func partialUpdate() {
        channelController.partialChannelUpdate(
            extraData: [
                "source": .string("user"),
                "source_detail": .dictionary(["user_id": .number(123)]),
                "channel_detail": .dictionary([
                    "topic": .string("Plants and Animals"),
                    "rating": .string("pg")
                ])
            ]
        ) { error in
            if let error {
                // handle error
                suppressUnusedWarning(error)
            }
        }

        // let's change the source of this channel
        channelController.partialChannelUpdate(extraData:["source": "system"])

        // since it's system generated we no longer need source_detail
        channelController.partialChannelUpdate(unsetProperties: ["source_detail"])

        // and finally update one of the nested fields in the channel_detail
        channelController.partialChannelUpdate(extraData:["channel_detail.topic": "Nature"])

        // and maybe we decide we no longer need a rating
        channelController.partialChannelUpdate(unsetProperties: ["channel_detail.rating"])
    }

    func fullUpdate() {
        let channelController = chatClient.channelController(for: .init(type: .messaging, id: "general"))

        channelController.updateChannel(
            name: "My special channel",
            imageURL: nil,
            team: nil,
            extraData: [
                "name": .string("myspecialchannel"),
                "color": .string("green"),
            ]
        ) { error in
            if let error {
                // handle error
                suppressUnusedWarning(error)
            }
        }
    }
}
