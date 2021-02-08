// LINK: https://getstream.io/chat/docs/ios-swift/?language=swift#messages

import StreamChat

func snippet_introduction_messages() {
    /// 1: Create a `ChannelId` that represents the channel you want to create.
    channelController.createNewMessage(text: "Hello") { result in
        switch result {
        case .success(let messageId):
            /// 2: Handle success
            print(messageId)
        case .failure(let error):
            /// 3: Handle errors
            print(error)
        }
    }
}
