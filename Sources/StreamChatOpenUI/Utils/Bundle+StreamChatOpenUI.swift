//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 17.0, macOS 14.0, *)
extension Bundle {
    static let streamChatOpenUI: Bundle = {
        #if SWIFT_PACKAGE
        return .module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }()
}

@available(iOS 17.0, macOS 14.0, *)
private final class BundleToken {}
