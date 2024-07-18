//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `ConnectionRecoveryHandler`
final class ConnectionRecoveryHandler_Mock: ConnectionRecoveryHandler {
    var startCallCount = 0
    var stopCallCount = 0

    func start() {
        startCallCount += 1
    }
    
    func stop() {
        stopCallCount += 1
    }
    
    lazy var mock_webSocketClientDidUpdateConnectionState = MockFunc.mock(for: webSocketClient)

    func webSocketClient(_ client: WebSocketClient, didUpdateConnectionState state: WebSocketConnectionState) {
        mock_webSocketClientDidUpdateConnectionState.call(with: (client, state))
    }
}
