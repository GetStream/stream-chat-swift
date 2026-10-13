//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Bundle {
    /// The bundle with the AI components' resources, such as their strings.
    static let streamChatAI: Bundle = {
        #if SWIFT_PACKAGE
        return .module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }()
}

private final class BundleToken {}
