// LINK: https://getstream.io/chat/docs/ios-swift/ios_user_setup_and_tokens/?preview=1&language=swift

import StreamChat

private var chatClient: ChatClient!

func snippet_ux_client_user_setup_tokens_basic_setup() {
    // > import StreamChat

    /// 1: Create a static token provider. Use it for testing purposes.
    let tokenProvider = TokenProvider.static(Token("{{ chat_user_token }}"))

    /// 2: Create a `ChatClientConfig` with the API key.
    let config = ChatClientConfig(apiKeyString: "{{ api_key }}")

    /// 3: Create a `ChatClient` instance with the config and the token provider.
    chatClient = ChatClient(config: config, tokenProvider: tokenProvider)
}
