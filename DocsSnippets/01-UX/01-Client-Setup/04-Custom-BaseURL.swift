// LINK: https://getstream.io/chat/docs/ios-swift/ios_client_setup/?preview=1&language=swift#2.-you-can-specify-a-custom-stream%C2%A0baseurl

import StreamChat

private var chatClient: ChatClient!
private var tokenProvider: TokenProvider!

func snippet_ux_client_setup_custom_baseURL() {
    // > import StreamChat

    /// 1: Create a `ChatClientConfig` with the API key.
    var config = ChatClientConfig(apiKeyString: "{{ api_key }}")

    /// 2: Set the config's baseURL
    config.baseURL = .singapore // .dublin, .usEast, .sydney

    // or

    config.baseURL = .init(url: URL(string: "www.your-custom-url.com")!)

    /// 3: Create a `ChatClient` instance with the config and the token provider.
    chatClient = ChatClient(config: config, tokenProvider: tokenProvider)
}
