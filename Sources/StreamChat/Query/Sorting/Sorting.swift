//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A sorting key protocol.
public protocol SortingKey: Encodable, Sendable {}

/// Sorting options.
///
/// For example:
/// ```
/// // Sort channels by the last message date:
/// let sorting = Sorting("lastMessageDate")
/// ```
public struct Sorting<Key: SortingKey>: Encodable, CustomStringConvertible, Sendable {
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

/// A sorting key that can be converted to local DB query or local runtime sorting.
public struct LocalConvertibleSortingKey<Model>: SortingKey, Encodable, Equatable {
    let keyPath: PartialKeyPath<Model>?
    let localKey: String?
    let remoteKey: String
    var requiresRuntimeSorting: Bool {
        localKey == nil
    }

    init(keyPath: PartialKeyPath<Model>?, localKey: String?, remoteKey: String) {
        self.keyPath = keyPath
        self.localKey = localKey
        self.remoteKey = remoteKey
    }

    init(localKey: String?, remoteKey: String) {
        keyPath = nil
        self.localKey = localKey
        self.remoteKey = remoteKey
    }

    public static func custom<Value>(keyPath: KeyPath<Model, Value>, key: String) -> Self {
        .init(keyPath: keyPath, localKey: nil, remoteKey: key)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(remoteKey)
    }
}

extension LocalConvertibleSortingKey: CustomDebugStringConvertible {
    public var debugDescription: String {
        remoteKey
    }

    func sortDescriptor(isAscending: Bool) -> NSSortDescriptor? {
        guard let localKey = self.localKey else {
            return nil
        }
        return .init(key: localKey, ascending: isAscending)
    }

    func sortValue(isAscending: Bool) -> SortValue<Model>? {
        guard let keyPath = keyPath else {
            return nil
        }
        return SortValue(keyPath: keyPath, isAscending: isAscending)
    }
}

/// A protocol for queries that can be converted to local sorting.
protocol LocalConvertibleSortingQuery {
    associatedtype Model
    var sort: [Sorting<LocalConvertibleSortingKey<Model>>] { get }
}

extension LocalConvertibleSortingQuery {
    var requiresRuntimeSorting: Bool {
        sort.contains { $0.key.requiresRuntimeSorting }
    }

    /// Returns the sort values for runtime sorting.
    /// If one of the sort keys requires runtime sorting, all sort values will be used
    /// for runtime sorting.
    var runtimeSortingValues: [SortValue<Model>] {
        if !requiresRuntimeSorting {
            return []
        }
        return sort.compactMap { $0.key.sortValue(isAscending: $0.isAscending) }
    }
}
