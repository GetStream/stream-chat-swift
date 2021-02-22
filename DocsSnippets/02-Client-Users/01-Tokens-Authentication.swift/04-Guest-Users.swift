// LINK: https://getstream.io/chat/docs/ios-swift/tokens_and_authentication/?preview=1&language=swift#guest-users

import StreamChat

private var chatClient: ChatClient!

func snippet_client_users_tokens_authentication_guest_users() {
    // > import StreamChat

    /// 1: Create a guest token provider.
    let tokenProvider = TokenProvider.guest(userId: "john-doe")

    /// 2: Create a `ChatClientConfig` with the API key.
    let config = ChatClientConfig(apiKeyString: "{{ api_key }}")

    /// 3: Create a `ChatClient` instance with the config and the token provider.
    chatClient = ChatClient(config: config, tokenProvider: tokenProvider)
}
