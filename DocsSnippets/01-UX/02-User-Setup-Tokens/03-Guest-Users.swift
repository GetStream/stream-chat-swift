// LINK:  https://getstream.io/chat/docs/ios-swift/ios_user_setup_and_tokens/?preview=1&language=swift#guest-users

import StreamChat

private var chatClient: ChatClient!

func snippet_ux_user_setup_tokens_guest_users() {
    // > import StreamChat

    /// 1: Create a guest token provider.
    let tokenProvider = TokenProvider.guest(userId: "john-doe")

    /// 2: Create a `ChatClientConfig` with the API key.
    let config = ChatClientConfig(apiKeyString: "{{ api_key }}")

    /// 3: Create a `ChatClient` instance with the config and the token provider.
    chatClient = ChatClient(config: config, tokenProvider: tokenProvider)
}
