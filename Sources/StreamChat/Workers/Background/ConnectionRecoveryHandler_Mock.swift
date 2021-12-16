//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

/// Mock implementation of `ConnectionRecoveryHandler`
final class ConnectionRecoveryHandlerMock: ConnectionRecoveryHandler {
    lazy var mock_webSocketClientDidUpdateConnectionState = MockFunc.mock(for: webSocketClient)
    
    func webSocketClient(_ client: WebSocketClient, didUpdateConnectionState state: WebSocketConnectionState) {
        mock_webSocketClientDidUpdateConnectionState.call(with: (client, state))
    }
}
