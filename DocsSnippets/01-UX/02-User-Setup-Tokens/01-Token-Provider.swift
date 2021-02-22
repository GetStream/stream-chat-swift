// LINK:  https://getstream.io/chat/docs/ios-swift/ios_user_setup_and_tokens/?preview=1&language=swift#token-provider-(recommended)

import StreamChat

private var chatClient: ChatClient!

func snippet_ux_user_setup_tokens_token_provider() {
    // > import StreamChat

    /// 1: Create a token provider that fetches the token from your backend service.
    let tokenProvider = TokenProvider.closure { _, completion in
        let token: Token? = nil
        let error: Error? = nil

        // TODO: Fetch a token locally or use URLSession/Alamofire/etc to fetch
        /// a token from your backend service and pass it into completion

        if let token = token {
            completion(.success(token))
        } else if let error = error {
            completion(.failure(error))
        }
    }

    /// 2: Create a `ChatClientConfig` with the API key.
    let config = ChatClientConfig(apiKeyString: "{{ api_key }}")

    /// 3: Create a `ChatClient` instance with the config and the token provider.
    chatClient = ChatClient(config: config, tokenProvider: tokenProvider)
}
