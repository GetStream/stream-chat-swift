//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// Mock implementation of `WebSocketClient`.
final class WebSocketClient_Mock: WebSocketClient {
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
    var disconnect_completion: (() -> Void)?


    var mockedConnectionState: WebSocketConnectionState?

    override var connectionState: WebSocketConnectionState {
        return mockedConnectionState ?? super.connectionState
    }

    init(
        sessionConfiguration: URLSessionConfiguration = .ephemeral,
        requestEncoder: RequestEncoder = DefaultRequestEncoder(baseURL: .unique(), apiKey: .init(.unique)),
        eventDecoder: AnyEventDecoder = EventDecoder(),
        eventNotificationCenter: EventNotificationCenter = EventNotificationCenter_Mock(database: DatabaseContainer_Spy()),
        pingController: WebSocketPingController? = nil,
        webSocketEngine: WebSocketEngine? = nil,
        eventBatcher: EventBatcher? = nil
    ) {
        var environment = WebSocketClient.Environment.mock
        if let pingController = pingController {
            environment.createPingController = { _, _ in pingController }
        }

        if let webSocketEngine = webSocketEngine {
            environment.createEngine = { _, _, _ in webSocketEngine }
        }

        if let eventBatcher = eventBatcher {
            environment.eventBatcherBuilder = { _ in eventBatcher }
        }

        init_sessionConfiguration = sessionConfiguration
        init_requestEncoder = requestEncoder
        init_eventDecoder = eventDecoder
        init_eventNotificationCenter = eventNotificationCenter
        init_environment = environment

        super.init(sessionConfiguration: sessionConfiguration,
                  requestEncoder: requestEncoder,
                  eventDecoder: eventDecoder,
                  eventNotificationCenter: eventNotificationCenter,
                  environment: environment)
    }

    override func connect() {
        _connect_calledCounter { $0 += 1 }
    }

    override func disconnect(
        source: WebSocketConnectionState.DisconnectionSource = .userInitiated,
        completion: @escaping () -> Void
    ) {
        _disconnect_calledCounter { $0 += 1 }
        disconnect_source = source
        disconnect_completion = completion
    }

    var mockEventsBatcher: EventBatcher_Mock {
        eventsBatcher as! EventBatcher_Mock
    }
}

extension WebSocketClient.Environment {
    static var mock: Self {
        .init(
            createPingController: WebSocketPingController_Mock.init,
            createEngine: WebSocketEngine_Mock.init,
            eventBatcherBuilder: { EventBatcher_Mock(handler: $0) }
        )
    }
}
