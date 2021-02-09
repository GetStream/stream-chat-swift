//
//  04-Anonymous-Users.swift
//  DocsSnippets
//
//  Created by Matheus Cardoso on 09/02/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

fileprivate var chatClient: ChatClient!

func snippet_ux_user_setup_tokens_anonymous_users() {
    //> import StreamChat

    /// 1: Create an anonymous token provider.
    let tokenProvider = TokenProvider.anonymous

    /// 2: Create a `ChatClientConfig` with the API key.
    let config = ChatClientConfig(apiKeyString: "{{ api_key }}")

    /// 3: Create a `ChatClient` instance with the config and the token provider.
    chatClient = ChatClient(config: config, tokenProvider: tokenProvider)
}

