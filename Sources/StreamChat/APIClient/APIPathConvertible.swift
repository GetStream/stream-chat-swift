//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Object representing path on API
protocol APIPathConvertible {
    /// Build APi path representing `self`
    var apiPath: String { get }
}
