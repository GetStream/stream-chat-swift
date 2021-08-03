//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools

/// Mock implementation of `WebSocketClient`.
class WebSocketClientMock: WebSocketClient {
    let init_sessionConfiguration: URLSessionConfiguration
    let init_requestEncoder: RequestEncoder
    let init_eventDecoder: AnyEventDecoder
    let init_eventNotificationCenter: EventNotificationCenter
    let init_internetConnection: InternetConnection
    let init_reconnectionStrategy: WebSocketClientReconnectionStrategy
    let init_environment: WebSocketClient.Environment

    @Atomic var connect_calledCounter = 0
    @Atomic var disconnect_calledCounter = 0

    override init(
        sessionConfiguration: URLSessionConfiguration,
        requestEncoder: RequestEncoder,
        eventDecoder: AnyEventDecoder,
        eventNotificationCenter: EventNotificationCenter,
        internetConnection: InternetConnection,
        reconnectionStrategy: WebSocketClientReconnectionStrategy = DefaultReconnectionStrategy(),
        environment: WebSocketClient.Environment = .init()
    ) {
        init_sessionConfiguration = sessionConfiguration
        init_requestEncoder = requestEncoder
        init_eventDecoder = eventDecoder
        init_eventNotificationCenter = eventNotificationCenter
        init_internetConnection = internetConnection
        init_reconnectionStrategy = reconnectionStrategy
        init_environment = environment

        super.init(
            sessionConfiguration: sessionConfiguration,
            requestEncoder: requestEncoder,
            eventDecoder: eventDecoder,
            eventNotificationCenter: eventNotificationCenter,
            internetConnection: internetConnection,
            reconnectionStrategy: reconnectionStrategy,
            environment: environment
        )
    }

    override func connect() {
        _connect_calledCounter { $0 += 1 }
    }

    override func disconnect(source: WebSocketConnectionState.DisconnectionSource = .userInitiated) {
        _disconnect_calledCounter { $0 += 1 }
    }
}

extension WebSocketClientMock {
    convenience init() {
        self.init(
            sessionConfiguration: .ephemeral,
            requestEncoder: DefaultRequestEncoder(baseURL: .unique(), apiKey: .init(.unique)),
            eventDecoder: EventDecoder(),
            eventNotificationCenter: EventNotificationCenterMock(database: DatabaseContainerMock()),
            internetConnection: InternetConnection()
        )
    }
}
