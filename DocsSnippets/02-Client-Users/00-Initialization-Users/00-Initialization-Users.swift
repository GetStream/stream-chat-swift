// LINK: https://getstream.io/chat/docs/ios-swift/init_and_users/?preview=1&language=swift

import StreamChat

private var chatClient: ChatClient!

func snippets_client_users_initialization_users() {
    /// 1: Create a static token provider. Use it for testing purposes.
    let token = Token("{{ chat_user_token }}")
    let tokenProvider = TokenProvider.static(token)

    /// 2: Create a `ChatClientConfig` with the API key.
    let config = ChatClientConfig(apiKeyString: "{{ api_key }}")

    /// 3: Create a `ChatClient` instance with the config and the token provider.
    chatClient = ChatClient(config: config, tokenProvider: tokenProvider)
}
