//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension FileManager {
    var streamStorageDirectory: URL? {
        #if os(tvOS)
        // tvOS apps can write only to Caches, which the system may purge while the app isn't running.
        urls(for: .cachesDirectory, in: .userDomainMask).first
        #else
        urls(for: .documentDirectory, in: .userDomainMask).first
        #endif
    }
}
