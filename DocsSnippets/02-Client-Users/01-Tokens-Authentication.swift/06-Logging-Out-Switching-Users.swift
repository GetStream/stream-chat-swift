// LINK: https://getstream.io/chat/docs/ios-swift/tokens_and_authentication/?preview=1&language=swift#anonymous-users

import StreamChat

private var chatClient: ChatClient!

func snippet_client_users_tokens_authentication_logging_out_switching_users() {
    // > import StreamChat

    chatClient.tokenProvider = .static(Token("{{ chat_user_Token }}"))
    chatClient.currentUserController().reloadUserIfNeeded()
}
