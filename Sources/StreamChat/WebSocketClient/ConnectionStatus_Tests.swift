//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class ChatClientConnectionStatus_Tests: XCTestCase {
    func test_wsConnectionState_isTranslatedCorrectly() {
        let testError = ClientError(with: TestError())
        let pairs: [(WebSocketConnectionState, ConnectionStatus)] = [
            (.disconnected(error: testError), .disconnected(error: testError)),
            (.connecting, .connecting),
            (.waitingForConnectionId, .connecting),
            (.waitingForReconnect(error: testError), .connecting),
            (.connected(connectionId: .unique), .connected),
            (.disconnecting(source: .noPongReceived), .disconnecting),
            (.disconnecting(source: .serverInitiated(error: testError)), .disconnecting),
            (.disconnecting(source: .systemInitiated), .disconnecting),
            (.disconnecting(source: .userInitiated), .disconnecting)
        ]
        
        pairs.forEach {
            XCTAssertEqual($1, ConnectionStatus(webSocketConnectionState: $0))
        }
    }
}
