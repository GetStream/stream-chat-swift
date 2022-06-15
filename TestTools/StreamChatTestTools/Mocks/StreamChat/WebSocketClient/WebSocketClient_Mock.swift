//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

/// Mock implementation of `WebSocketClient`.
final class WebSocketClient_Mock: WebSocketClient {
    let init_sessionConfiguration: URLSessionConfiguration
    let init_requestEncoder: RequestEncoder
    let init_eventDecoder: AnyEventDecoder
    let init_eventNotificationCenter: EventNotificationCenter
    let init_environment: WebSocketClient.Environment

    @Atomic var connect_calledCounter = 0
    var connect_called: Bool { connect_calledCounter > 0 }
    var connect_expectation: XCTestExpectation = .init()

    @Atomic var disconnect_calledCounter = 0
    var disconnect_source: WebSocketConnectionState.DisconnectionSource?
    var disconnect_called: Bool { disconnect_calledCounter > 0 }
    var disconnect_completion: (() -> Void)?
    var disconnect_expectation: XCTestExpectation = .init()

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
        connect_expectation.fulfill()
    }

    override func disconnect(
        source: WebSocketConnectionState.DisconnectionSource = .userInitiated,
        completion: @escaping () -> Void
    ) {
        _disconnect_calledCounter { $0 += 1 }
        disconnect_source = source
        disconnect_completion = completion
        disconnect_expectation.fulfill()
    }
    
    func cleanUp() {
        disconnect_calledCounter = 0
        disconnect_source = nil
        disconnect_completion = nil
        disconnect_expectation = .init()
        
        connect_calledCounter = 0
        connect_expectation = .init()
    }
    
    var mockEventsBatcher: EventBatcher_Mock {
        eventsBatcher as! EventBatcher_Mock
    }
}

extension WebSocketClient_Mock {
    convenience init() {
        self.init(
            sessionConfiguration: .ephemeral,
            requestEncoder: DefaultRequestEncoder(baseURL: .unique(), apiKey: .init(.unique)),
            eventDecoder: EventDecoder(),
            eventNotificationCenter: EventNotificationCenter_Mock(database: DatabaseContainer_Spy())
        )
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
