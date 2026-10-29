//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

extension XCUIElement {
    /// For elements that appear only after a mock server round trip or a websocket event.
    static var longWaitTimeout: Double { 15 }

    /// For optional elements that may never appear, such as a picker step that depends on the OS version.
    static var probeTimeout: Double { 3 }
}
