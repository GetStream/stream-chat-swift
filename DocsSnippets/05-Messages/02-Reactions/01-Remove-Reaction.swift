// LINK: https://getstream.io/chat/docs/ios-swift/send_reaction/?language=swift&preview=1#removing-a-reaction

import StreamChat

private var messageController: ChatMessageController!

func snippet_messages_reactions_remove_reaction() {
    messageController.deleteReaction("like") { error in
        print(error ?? "like removed")
    }
}
