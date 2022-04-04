//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Array where Element == URLQueryItem {
    /// Returns the value of the URLQueryItem with the given name. Returns `nil` if the query item doesn't exist.
    subscript(_ name: String) -> String? {
        first(where: { $0.name == name }).flatMap(\.value)
    }
}
