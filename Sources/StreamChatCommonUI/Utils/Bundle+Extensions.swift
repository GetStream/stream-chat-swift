//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

private class BundleIdentifyingClass {}

public extension Bundle {
    static var streamChatCommonUI: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #elseif STATIC_LIBRARY
        return Bundle.main
            .url(forResource: "StreamChatCommonUIResources", withExtension: "bundle")
            .flatMap(Bundle.init(url:))!
        #else
        return Bundle(for: BundleIdentifyingClass.self)
        #endif
    }
}
