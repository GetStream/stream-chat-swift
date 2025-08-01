//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Data cache.
///
/// - important: The implementation must be thread safe.
protocol DataCaching: Sendable {
    /// Retrieves data from cache for the given key.
    func cachedData(for key: String) -> Data?

    /// Returns `true` if the cache contains data for the given key.
    func containsData(for key: String) -> Bool

    /// Stores data for the given key.
    /// - note: The implementation must return immediately and store data
    /// asynchronously.
    func storeData(_ data: Data, for key: String)

    /// Removes data for the given key.
    func removeData(for key: String)

    /// Removes all items.
    func removeAll()
}
