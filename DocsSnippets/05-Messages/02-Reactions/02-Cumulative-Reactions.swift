// LINK: https://getstream.io/chat/docs/ios-swift/send_reaction/?language=swift&preview=1#removing-a-reaction

import StreamChat

private var messageController: ChatMessageController!

func snippet_messages_reactions_cumulative_reaction() {
    messageController.addReaction("like", score: 2) { error in
        print(error ?? "message liked twice")
    }
}
