// LINK: https://getstream.io/chat/docs/ios-swift/send_message/?preview=1&language=swift#complex-example

import StreamChat

private var chatClient: ChatClient!

func snippet_messages_overview_complex_send_message() {
    // > import StreamChat

    /// This example will add a custom attachment to a message

    /// 1: Create a `ChannelId` that represents the channel you want to send a message to.
    let channelId = ChannelId(type: .messaging, id: "general")

    /// 2: Use the `ChatClient` to create a `ChatChannelController` with the `ChannelId`.
    let channelController = chatClient.channelController(for: channelId)

    /// 3: Create a product structure that conforms to `AttachmentEnvelope`
    struct ProductAttachment: AttachmentEnvelope {
        var type: AttachmentType = .image
        
        let id: String
        let name: String
        let price: Int
    }

    /// 4: Instantiate the product attachment
    let iPhone = ProductAttachment(id: "iPhone13,3", name: "iPhone 12 Pro", price: 999)

    /// 4: Call `ChatChannelController.createNewMessage` to create the message with the custom attachment.
    channelController.createNewMessage(text: "Hello", attachments: [iPhone]) { result in
        switch result {
        case let .success(messageId):
            print(messageId)
        case let .failure(error):
            print(error)
        }
    }
}
