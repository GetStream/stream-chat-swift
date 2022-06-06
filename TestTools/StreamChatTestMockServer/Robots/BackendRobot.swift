//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
        let id = server.currentChannelId.isEmpty ? "general" : server.currentChannelId
        guard var config = server.config(forChannelId: id) else {
            return self
        }
        config.readEvents = value
        server.updateConfig(config: config, forChannelWithId: id)
        return self
    }

    @discardableResult
    public func setCooldown(enabled value: Bool, duration: Int) -> Self {
        let id = server.currentChannelId.isEmpty ? "general" : server.currentChannelId
        server.setCooldown(enabled: value, duration: duration, inChannelWithId: id)
        return self
    }
}
