//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension URL {
    /// Enriches `URL` with `http` scheme if it's missing
    var enrichedURL: URL {
        guard scheme == nil else {
            return self
        }

        return URL(string: "http://" + absoluteString) ?? self
    }
}
