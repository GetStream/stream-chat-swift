//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

// MARK: Robot
protocol Robot: AnyObject { }

enum SwitchState {
    case on
    case off
}

enum ElementState {
    case enabled(isEnabled: Bool)
    case visible(isVisible: Bool)
    case focused(isFocused: Bool)

    var errorMessage: String {
        let state: String
        switch self {
        case let .enabled(isEnabled):
            state = isEnabled ? "enabled" : "disabled"
        case let .focused(isFocused):
            state = isFocused ? "in focus" : "out of focus"
        case let .visible(isVisible):
            state = isVisible ? "visible" : "hidden"
        }
        return "Element should be \(state)"
    }
}

extension Robot {
    
    func step(_ name: String, step: () -> Void) {
        XCTContext.runActivity(named: name) { _ in
            step()
        }
    }

    @discardableResult
    func dismissKeyboard() -> Self {
        app.swipeDown()
        return self
    }

}
