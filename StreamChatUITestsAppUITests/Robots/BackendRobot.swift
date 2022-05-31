//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

final class BackendRobot: Robot {

    enum Settings: String {
        case isLocalStorageEnabled

        var element: XCUIElement { app.switches[rawValue] }
    }

    private var server: StreamMockServer

    init(_ server: StreamMockServer) {
        self.server = server
    }

    @discardableResult
    func delayServerResponse(byTimeInterval timeInterval: TimeInterval) -> Self {
        StreamMockServer.httpResponseDelay = timeInterval
        return self
    }

    @discardableResult
    func setReadEvents(to value: Bool) -> Self {
        let id = server.currentChannelId.isEmpty ? "general" : server.currentChannelId
        guard var config = server.config(forChannelId: id) else {
            return self
        }
        config.readEvents = value
        server.updateConfig(config: config, forChannelWithId: id)
        return self
    }

    @discardableResult
    func setCooldown(enabled value: Bool, duration: Int) -> Self {
        let id = server.currentChannelId.isEmpty ? "general" : server.currentChannelId
        server.setCooldown(enabled: value, duration: duration, inChannelWithId: id)
        return self
    }
}

// MARK: Config

extension BackendRobot {

    @discardableResult
    func setIsLocalStorageEnabled(to state: SwitchState) -> Self {
        setSwitchState(Settings.isLocalStorageEnabled.element, state: state)
    }
}
