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

    @discardableResult
    func delayServerResponse(byTimeInterval timeInterval: TimeInterval) -> Self {
        StreamMockServer.httpResponseDelay = timeInterval
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
