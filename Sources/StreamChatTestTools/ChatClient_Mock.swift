//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension ChatClient {
    /// Create a new instance of mock `ChatClient`
    static func mock(isLocalStorageEnabled: Bool = false) -> ChatClient {
        var config = ChatClientConfig(apiKey: .init("--== Mock ChatClient ==--"))
        config.isLocalStorageEnabled = isLocalStorageEnabled
        config.isClientInActiveMode = false
        
        return .init(
            config: config,
            environment: .init(
                apiClientBuilder: APIClient_Mock.init,
                webSocketClientBuilder: {
                    WebSocketClient_Mock(
                        sessionConfiguration: $0,
                        requestEncoder: $1,
                        eventDecoder: $2,
                        eventNotificationCenter: $3
                    )
                },
                databaseContainerBuilder: {
                    try DatabaseContainerMock(
                        kind: $0,
                        shouldFlushOnStart: $1,
                        shouldResetEphemeralValuesOnStart: $2,
                        localCachingSettings: $3,
                        deletedMessagesVisibility: $4,
                        shouldShowShadowedMessages: $5
                    )
                }
            )
        )
    }
}

// ===== TEMP =====

class APIClient_Mock: APIClient {
    override func request<Response>(
        endpoint: Endpoint<Response>,
        completion: @escaping (Result<Response, Error>) -> Void
    ) where Response: Decodable {
        // Do nothing for now
    }
}

class WebSocketClient_Mock: WebSocketClient {
    override func connect() {
        // Do nothing for now
    }
}
