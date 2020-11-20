//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

private class BundleIdentifyingClass {}

extension Bundle {
    static var streamChatUI: Bundle {
        Bundle(for: BundleIdentifyingClass.self)
    }
}
