// LINK: https://getstream.io/chat/docs/ios-swift/anon/?preview=1&language=swift

import StreamChat

private var chatClient: ChatClient!

func snippet_client_users_anonymous_users() {
    // > import StreamChat

    /// 1: Create an anonymous token provider.
    let tokenProvider = TokenProvider.anonymous

    /// 2: Create a `ChatClientConfig` with the API key.
    let config = ChatClientConfig(apiKeyString: "{{ api_key }}")

    /// 3: Create a `ChatClient` instance with the config and the token provider.
    chatClient = ChatClient(config: config, tokenProvider: tokenProvider)
}
