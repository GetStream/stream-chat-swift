// LINK: https://getstream.io/chat/docs/ios-swift/send_message/?preview=1&language=javascript#delete-a-message

import StreamChat

private var messageController: ChatMessageController!

func snippet_messages_overview_delete_message() {
    messageController.deleteMessage { error in
        // handle possible errors
        print(error ?? "success")
    }
}
