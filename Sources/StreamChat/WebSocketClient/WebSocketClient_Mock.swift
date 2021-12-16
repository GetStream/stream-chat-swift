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
    let init_environment: WebSocketClient.Environment

    @Atomic var connect_calledCounter = 0
    var connect_called: Bool { connect_calledCounter > 0 }
    
    @Atomic var disconnect_calledCounter = 0
    var disconnect_source: WebSocketConnectionState.DisconnectionSource?
    var disconnect_called: Bool { disconnect_calledCounter > 0 }

    override init(
        sessionConfiguration: URLSessionConfiguration,
        requestEncoder: RequestEncoder,
        eventDecoder: AnyEventDecoder,
        eventNotificationCenter: EventNotificationCenter,
        environment: WebSocketClient.Environment = .mock
    ) {
        init_sessionConfiguration = sessionConfiguration
        init_requestEncoder = requestEncoder
        init_eventDecoder = eventDecoder
        init_eventNotificationCenter = eventNotificationCenter
        init_environment = environment

        super.init(
            sessionConfiguration: sessionConfiguration,
            requestEncoder: requestEncoder,
            eventDecoder: eventDecoder,
            eventNotificationCenter: eventNotificationCenter,
            environment: environment
        )
    }

    override func connect() {
        _connect_calledCounter { $0 += 1 }
    }

    override func disconnect(source: WebSocketConnectionState.DisconnectionSource = .userInitiated) {
        _disconnect_calledCounter { $0 += 1 }
        disconnect_source = source
    }
    
    var mockEventsBatcher: EventBatcherMock {
        eventsBatcher as! EventBatcherMock
    }
}

extension WebSocketClientMock {
    convenience init() {
        self.init(
            sessionConfiguration: .ephemeral,
            requestEncoder: DefaultRequestEncoder(baseURL: .unique(), apiKey: .init(.unique)),
            eventDecoder: EventDecoder(),
            eventNotificationCenter: EventNotificationCenterMock(database: DatabaseContainerMock())
        )
    }
}

extension WebSocketClient.Environment {
    static var mock: Self {
        .init(
            createPingController: WebSocketPingControllerMock.init,
            createEngine: WebSocketEngineMock.init,
            eventBatcherBuilder: { EventBatcherMock(handler: $0) }
        )
    }
}
