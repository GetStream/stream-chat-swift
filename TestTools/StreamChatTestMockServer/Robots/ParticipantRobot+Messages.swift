//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension ParticipantRobot {
    /// Sends a system message, like the ones the backend posts for server-side actions.
    @discardableResult
    func sendSystemMessage(_ text: String) -> ParticipantRobot {
        let body = text.data(using: .utf8) ?? Data()
        _ = mockServer.postRequest(endpoint: "participant/message?system=true", body: body)
        return self
    }

    /// Sends a message to the channel with the given name instead of the current channel.
    @discardableResult
    func sendMessage(_ text: String, inChannelNamed channelName: String) -> ParticipantRobot {
        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: "channel_name", value: channelName)]
        let body = text.data(using: .utf8) ?? Data()
        _ = mockServer.postRequest(endpoint: "participant/message?\(components.percentEncodedQuery ?? "")", body: body)
        return self
    }
}
