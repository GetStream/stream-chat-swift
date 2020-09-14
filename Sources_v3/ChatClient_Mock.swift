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
    
    var mockAPIClient: APIClientMock {
        apiClient as! APIClientMock
    }
    
    var mockWebSocketClient: WebSocketClientMock {
        webSocketClient as! WebSocketClientMock
    }
    
    var mockDatabaseContainer: DatabaseContainerMock {
        databaseContainer as! DatabaseContainerMock
    }
}

extension Client.Environment where ExtraData == DefaultDataTypes {
    static var mock: ChatClient.Environment {
        .init(
            apiClientBuilder: APIClientMock.init,
            webSocketClientBuilder: {
                WebSocketClientMock(
                    connectEndpoint: $0,
                    sessionConfiguration: $1,
                    requestEncoder: $2,
                    eventDecoder: $3,
                    eventNotificationCenter: $4,
                    internetConnection: $5
                )
            },
            databaseContainerBuilder: { try! DatabaseContainerMock(kind: $0) },
            requestEncoderBuilder: DefaultRequestEncoder.init,
            requestDecoderBuilder: DefaultRequestDecoder.init,
            eventDecoderBuilder: EventDecoder.init,
            notificationCenterBuilder: EventNotificationCenter.init
        )
    }
}
