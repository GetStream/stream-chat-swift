//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public extension String {
    /// Returns a new unique string
    static var unique: String { UUID().uuidString }
}
