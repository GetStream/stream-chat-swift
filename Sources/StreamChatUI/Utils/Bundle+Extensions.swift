//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

private class BundleIdentifyingClass {}

public extension Bundle {
    static var streamChatUI: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: BundleIdentifyingClass.self)
        #endif
    }
}
