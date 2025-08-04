//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class WebSocketPingController_Mock: WebSocketPingController, @unchecked Sendable {
    var connectionStateDidChange_connectionStates: [WebSocketConnectionState] = []
    var pongReceivedCount = 0

    override func connectionStateDidChange(_ connectionState: WebSocketConnectionState) {
        connectionStateDidChange_connectionStates.append(connectionState)
        super.connectionStateDidChange(connectionState)
    }

    override func pongReceived() {
        pongReceivedCount += 1
        super.pongReceived()
    }
}
