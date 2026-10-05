//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension BackendRobot {
    /// Generates channels, naming the first ones after `channelNames` in channel order.
    /// Channels without an entry keep their positional name ("1", "2", ...).
    @discardableResult
    func generateChannels(
        channelsCount: Int,
        channelNames: [String],
        messagesCount: Int = 0
    ) -> BackendRobot {
        waitForMockServerToStart()
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "channel_names", value: channelNames.joined(separator: ",")),
            URLQueryItem(name: "channels", value: "\(channelsCount)"),
            URLQueryItem(name: "messages", value: "\(messagesCount)")
        ]
        let query = components.percentEncodedQuery ?? ""
        _ = mockServer.postRequest(endpoint: "mock?\(query)")
        return self
    }

    /// Truncates the current channel as a server-side action.
    @discardableResult
    func truncateChannel(withMessage: Bool) -> BackendRobot {
        waitForMockServerToStart()
        _ = mockServer.postRequest(endpoint: "truncate_channel?with_message=\(withMessage)")
        return self
    }
}
