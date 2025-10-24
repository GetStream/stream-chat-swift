//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamCore

// A concrete `WebSocketPingControllerDelegate` implementation allowing capturing the delegate calls
final class WebSocketPingController_Delegate: WebSocketPingControllerDelegate {
    var sendPing_calledCount = 0
    var disconnectOnNoPongReceived_calledCount = 0

    func sendPing() {
        sendPing_calledCount += 1
    }

    func sendPing(healthCheckEvent: any SendableEvent) {
        sendPing_calledCount += 1
    }

    func disconnectOnNoPongReceived() {
        disconnectOnNoPongReceived_calledCount += 1
    }
}
