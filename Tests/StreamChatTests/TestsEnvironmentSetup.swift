//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Class encapsulating one-time setup code for all the tests of `StreamChatUITests`.
final class UITestsEnvironmentSetup: NSObject {
    override init() {
        NSTimeZone.default = TimeZone(secondsFromGMT: 0)!
    }
}
