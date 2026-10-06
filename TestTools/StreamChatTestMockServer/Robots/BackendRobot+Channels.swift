//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

public extension BackendRobot {
    /// Generates channels, naming the first ones after `channelNames` in channel order.
    /// Channels without an entry keep their positional name ("1", "2", ...).
    /// The mock server receives the names comma-separated, so a name must not contain a comma.
    @discardableResult
    func generateChannels(
        channelsCount: Int,
        channelNames: [String],
        messagesCount: Int = 0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> BackendRobot {
        if let name = channelNames.first(where: { $0.contains(",") }) {
            XCTFail("Channel name '\(name)' contains a comma, which the mock server reads as a separator", file: file, line: line)
            return self
        }
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

    /// Mutes the current channel for the app user as a server-side action.
    @discardableResult
    func muteChannel() -> BackendRobot {
        waitForMockServerToStart()
        _ = mockServer.postRequest(endpoint: "mute_channel")
        return self
    }

    /// Adds a member to the current channel as a server-side action.
    @discardableResult
    func addMember(withUserId userId: String = "leia_organa") -> BackendRobot {
        waitForMockServerToStart()
        _ = mockServer.postRequest(endpoint: "add_member?user_id=\(userId)")
        return self
    }

    /// Removes a member from the current channel as a server-side action.
    @discardableResult
    func removeMember(withUserId userId: String) -> BackendRobot {
        waitForMockServerToStart()
        _ = mockServer.postRequest(endpoint: "remove_member?user_id=\(userId)")
        return self
    }

    /// Makes the mock centre the messages page around a message on the target, like the real backend,
    /// instead of returning the target and the newer messages only.
    @discardableResult
    func setCenteredAroundPagination(enabled: Bool = true) -> BackendRobot {
        waitForMockServerToStart()
        _ = mockServer.postRequest(endpoint: "config/centered_around_pagination?value=\(enabled)")
        return self
    }
}
