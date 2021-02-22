// LINK: https://getstream.io/chat/docs/ios-swift/?language=swift#chat-client

import StreamChat

private var chatClient: ChatClient!

func snippet_introduction_chatClient() {
    /// 1: Create a static token provider. Use it for testing purposes.
    let token = Token("{{ chat_user_token }}")
    let tokenProvider = TokenProvider.static(token)

    /// 2: Create a `ChatClientConfig` with the API key.
    let config = ChatClientConfig(apiKeyString: "{{ api_key }}")

    /// 3: Create a `ChatClient` instance with the config and the token provider.
    chatClient = ChatClient(config: config, tokenProvider: tokenProvider)
}
