//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public extension String {
    /// Returns a new unique string
    static var unique: String { UUID().uuidString }
}
