//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

/// Simulates device behavior
public final class DeviceRobot {

    enum Orientation {
        case portrait, landscape
    }

    enum ApplicationState {
        case foreground, background
    }

    @discardableResult
    func rotateDevice(_ orientation: Orientation) -> Self {
        switch orientation {
        case .portrait:
            app.portrait()
        case .landscape:
            app.landscape()
        }
        return self
    }

    @discardableResult
    func moveApplication(to state: ApplicationState) -> Self {
        switch state {
        case .background:
            XCUIDevice.shared.press(XCUIDevice.Button.home)
        case .foreground:
            app.activate()
        }
        return self
    }
}

