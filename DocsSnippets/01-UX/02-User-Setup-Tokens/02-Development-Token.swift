// LINK:  https://getstream.io/chat/docs/ios-swift/ios_user_setup_and_tokens/?preview=1&language=swift#development-token

import StreamChat

private var chatClient: ChatClient!

func snippet_ux_user_setup_tokens_development_token() {
    // > import StreamChat

    /// 1: Create a development token provider. Use it for testing purposes.
    let tokenProvider = TokenProvider.development(userId: "john-doe")

    /// 2: Create a `ChatClientConfig` with the API key.
    let config = ChatClientConfig(apiKeyString: "{{ api_key }}")

    /// 3: Create a `ChatClient` instance with the config and the token provider.
    chatClient = ChatClient(config: config, tokenProvider: tokenProvider)
}
