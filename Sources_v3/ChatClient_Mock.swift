//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatClient

extension ChatClient {
    static var mock: ChatClient {
        ChatClient(
            config: .init(apiKey: .init(.unique)),
            workerBuilders: [],
            environment: .mock
        )
    }
}

extension Client.Environment where ExtraData == DefaultDataTypes {
    static var mock: ChatClient.Environment {
        .init(
            apiClientBuilder: { _, _, _ in APIClientMock() },
            webSocketClientBuilder: { _, _, _, _, _, _ in WebSocketClientMock() },
            databaseContainerBuilder: { _ in DatabaseContainerMock() },
            requestEncoderBuilder: { _, _ in DefaultRequestEncoder(baseURL: .unique(), apiKey: .init(.unique)) },
            requestDecoderBuilder: { DefaultRequestDecoder() },
            eventDecoderBuilder: { EventDecoder() },
            notificationCenterBuilder: { _ in EventNotificationCenter() }
        )
    }
}
