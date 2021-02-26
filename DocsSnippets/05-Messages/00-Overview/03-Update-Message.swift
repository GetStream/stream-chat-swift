// LINK: https://getstream.io/chat/docs/ios-swift/send_message/?preview=1&language=swift#get-a-message

import StreamChat

private var messageController: ChatMessageController!

func snippet_messages_overview_update_message() {
    messageController.editMessage(text: "Hello!!!") { error in
        // handle possible errors / access message
        print(error ?? messageController.message!)
    }
}
