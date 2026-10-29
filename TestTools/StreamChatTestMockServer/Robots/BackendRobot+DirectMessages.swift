//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension BackendRobot {
    /// Generates the channels and, when `withDirectMessageChannel` is true, also a direct message
    /// channel between the app user and the participant.
    @discardableResult
    func generateChannels(
        channelsCount: Int,
        messagesCount: Int = 0,
        withDirectMessageChannel: Bool
    ) -> BackendRobot {
        waitForMockServerToStart()
        let endpoint = "mock?" +
            "dm=\(withDirectMessageChannel)&" +
            "channels=\(channelsCount)&" +
            "messages=\(messagesCount)"
        _ = mockServer.postRequest(endpoint: endpoint)
        return self
    }
}
