//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `ConnectionRecoveryHandler`
final class ConnectionRecoveryHandler_Mock: ConnectionRecoveryHandler {
    lazy var mock_webSocketClientDidUpdateConnectionState = MockFunc.mock(for: webSocketClient)
    
    func webSocketClient(_ client: WebSocketClient, didUpdateConnectionState state: WebSocketConnectionState) {
        mock_webSocketClientDidUpdateConnectionState.call(with: (client, state))
    }
}
