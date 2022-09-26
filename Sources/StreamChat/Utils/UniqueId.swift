//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension String {
    /// Creates and returns a new unique id every time the variable is accessed.
    static var newUniqueId: String { UUID().uuidString.lowercased() }
}
