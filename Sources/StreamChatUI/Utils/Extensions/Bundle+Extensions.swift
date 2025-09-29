//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

private class BundleIdentifyingClass {}

extension Bundle {
    static var streamChatUI: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #elseif STATIC_LIBRARY
        return Bundle.main
            .url(forResource: "StreamChatUIResources", withExtension: "bundle")
            .flatMap(Bundle.init(url:))!
        #else
        return Bundle(for: BundleIdentifyingClass.self)
        #endif
    }
}
