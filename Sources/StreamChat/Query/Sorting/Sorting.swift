//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// A sorting key protocol.
public protocol SortingKey: Encodable {
    associatedtype Object
}

/// Sorting options.
///
/// For example:
/// ```
/// // Sort channels by the last message date:
/// let sorting = Sorting("lastMessageDate")
/// ```
public struct Sorting<Key: SortingKey>: Encodable, CustomStringConvertible {
    /// A sorting field name.
    public let key: Key
    /// A sorting direction.
    public let direction: Int

    private enum CodingKeys: String, CodingKey {
        case key = "field"
        case direction
    }

    /// True if the sorting in ascending order, otherwise false.
    public var isAscending: Bool { direction == 1 }

    public var description: String { "\(key):\(direction)" }

    /// Init sorting options.
    ///
    /// - Parameters:
    ///     - key: a sorting key.
    ///     - isAscending: a direction of the sorting.
    public init(key: Key, isAscending: Bool = false) {
        self.key = key
        direction = isAscending ? 1 : -1
    }
}

extension Sorting: Equatable where Key: Equatable {}
extension Sorting: Hashable where Key: Hashable {}

extension Sorting {
    var sortValue: SortValue<Key.Object>? {
        guard let key = key as? ChannelListSortingKey,
              let keyPath = key.keyPath as? PartialKeyPath<Key.Object> else {
            return nil
        }
        return SortValue(keyPath: keyPath, isAscending: isAscending)
    }
}

extension Array where Element == Sorting<ChannelListSortingKey> {
    var customSorting: [SortValue<ChatChannel>] {
        var hasCustom = false
        let sortValues = compactMap {
            if $0.key.isCustom {
                hasCustom = true
            }
            return $0.sortValue
        }

        return hasCustom ? sortValues : []
    }
}
