//
//  ChatClientConfiguration.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 07/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

public extension ChatClient {
    static var shared: ChatClient = {
        var config = ChatClientConfig(apiKey: APIKey(ChatClientConfiguration.shared.apiKey))
        config.isLocalStorageEnabled = true
        config.shouldFlushLocalStorageOnStart = false
        let client = ChatClient(config: config) { completion in
            ChatClientConfiguration.shared.requestNewChatToken?()
            ChatClientConfiguration.shared.streamChatToken = { token in
                completion(.success(token))
            }
        }
        return client
    }()
}

open class ChatClientConfiguration {

    // MARK: - Variables
    public static let shared = ChatClientConfiguration()
    open var apiKey = ""
    open var streamChatToken: ((Token) -> Void)?
    open var requestNewChatToken: (() -> Void)?

    // MARK: - Init
    public init() {}
}
