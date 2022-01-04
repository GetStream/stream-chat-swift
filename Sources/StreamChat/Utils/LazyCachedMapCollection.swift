//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// Read-only collection that applies transformation to element on first access.
///
/// Compared to `LazyMapCollection` does not evaluate the whole collection on `count` call.
public struct LazyCachedMapCollection<Element>: RandomAccessCollection {
    public typealias Index = Int

    public func index(before i: Index) -> Index {
        cache.values.index(before: i)
    }

    public func index(after i: Index) -> Index {
        cache.values.index(after: i)
    }

    public var startIndex: Index { cache.values.startIndex }

    public var endIndex: Index { cache.values.endIndex }

    public var count: Index { cache.values.count }

    public init<Collection: RandomAccessCollection, SourceElement>(
        source: Collection,
        map: @escaping (SourceElement) -> Element
    ) where Collection.Element == SourceElement, Collection.Index == Index {
        generator = { map(source[$0]) }
        cache = .init(capacity: source.count)
    }

    private var generator: (Index) -> Element
    private var cache: Cache<Element>

    public subscript(position: Index) -> Element {
        if let cached = cache.values[position] {
            return cached
        } else {
            let value = generator(position)
            defer { cache.values[position] = value }
            return value
        }
    }
}

extension LazyCachedMapCollection: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Element

    public init(arrayLiteral elements: Element...) {
        generator = { elements[$0] }
        cache = .init(capacity: elements.count)
    }
}

extension LazyCachedMapCollection: Equatable where Element: Equatable {
    public static func == (lhs: LazyCachedMapCollection<Element>, rhs: LazyCachedMapCollection<Element>) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy(==)
    }
}

extension RandomAccessCollection where Index == Int {
    /// Lazily apply transformation to sequence
    public func lazyCachedMap<T>(_ transformation: @escaping (Element) -> T) -> LazyCachedMapCollection<T> {
        .init(source: self, map: transformation)
    }
}

// Must be class so it can be mutable while the collection isn't
private class Cache<Element> {
    init(capacity: Int) {
        values = ContiguousArray(repeating: nil, count: capacity)
    }

    var values: ContiguousArray<Element?>
}
