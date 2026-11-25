//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/silent-messages/

import StreamChat

struct Snippets_04_07_SilentMessages {
    var client: ChatClient!

    func silentMessages() {
        let channelController = client.channelController(for: .init(type: .messaging, id: "general"))
        channelController.createNewMessage(text: "You completed your trip", isSilent: true)
    }

    func systemMessages() {
        let channelController = client.channelController(for: .init(type: .messaging, id: "general"))
        channelController.createSystemMessage(text: "You completed your trip")
    }
}
