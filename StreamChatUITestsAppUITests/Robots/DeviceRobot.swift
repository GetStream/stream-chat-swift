//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

/// Simulates device behavior
final class DeviceRobot: Robot {

    enum Orientation {
        case portrait, landscape
    }

    enum ApplicationState {
        case foreground, background
    }

    enum Settings: String {
        case showsConnectivity
        case setConnectivity
        case isConnected
        var element: XCUIElement { app.switches[rawValue] }
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

// MARK: Connectivity

extension DeviceRobot {

    /// Toggles the visibility of the connectivity switch control. When set to `.on`, the switch control will be displayed in the navigation bar.
    @discardableResult
    func setConnectivitySwitchVisibility(to state: SwitchState) -> Self {
        setSwitchState(Settings.showsConnectivity.element, state: state)
    }

    /// Mocks device connectivity, When set to `.off` state, the internet connectivity is mocked, HTTP request fails with "No Internet Connection" error.
    ///
    /// Note: Requires `setConnectivitySwitchVisibility` needs to be set `.on` on first screen.
    @discardableResult
    func setConnectivity(to state: SwitchState) -> Self {
        setSwitchState(Settings.isConnected.element, state: state)
    }
}
