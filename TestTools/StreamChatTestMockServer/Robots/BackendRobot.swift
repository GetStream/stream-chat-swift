//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

public class BackendRobot {

    private var server: StreamMockServer

    public init(_ server: StreamMockServer) {
        self.server = server
    }

    @discardableResult
    public func delayServerResponse(byTimeInterval timeInterval: TimeInterval) -> Self {
        StreamMockServer.httpResponseDelay = timeInterval
        return self
    }

    @discardableResult
    public func setReadEvents(to value: Bool) -> Self {
        let id = server.currentChannelId.isEmpty ? server.getFirstChannelId() : server.currentChannelId
        guard var config = server.config(forChannelId: id) else {
            return self
        }
        config.readEvents = value
        server.updateConfig(config: config, forChannelWithId: id)
        return self
    }

    @discardableResult
    public func setCooldown(enabled value: Bool, duration: Int) -> Self {
        let id = server.currentChannelId.isEmpty ? server.getFirstChannelId() : server.currentChannelId
        server.setCooldown(enabled: value, duration: duration, inChannelWithId: id)
        return self
    }

    @discardableResult
    public func generateChannels(
        count: Int,
        messageText: String? = nil,
        messagesCount: Int = 0,
        replyCount: Int = 0,
        authorDetails: [String: String] = UserDetails.lukeSkywalker,
        memberDetails: [[String: String]] = [
            UserDetails.lukeSkywalker,
            UserDetails.hanSolo,
            UserDetails.countDooku
        ],
        withAttachments: Bool = false
    ) -> Self  {
        var json = server.channelList
        guard let sampleChannel = (json[JSONKey.channels] as? [[String: Any]])?.first else { return self }

        let userSources = TestData.toJson(.httpChatEvent)[JSONKey.event] as? [String: Any]

        let members = server.mockMembers(
            userSources: userSources,
            sampleChannel: sampleChannel,
            memberDetails: memberDetails
        )

        let author = server.setUpUser(source: userSources, details: authorDetails)
        let channels = server.mockChannels(
            count: count,
            messageText: messageText,
            messagesCount: messagesCount,
            replyCount: replyCount,
            author: author,
            members: members,
            sampleChannel: sampleChannel,
            withAttachments: withAttachments
        )

        json[JSONKey.channels] = channels
        server.channelList = json
        return self
    }
}
