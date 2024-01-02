//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
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
        map: @escaping (SourceElement) -> Element,
        context: NSManagedObjectContext? = nil
    ) where Collection.Element == SourceElement, Collection.Index == Index {
        // In v5 we should deprecate LazyCachedMapCollection since it is very error prone
        // And customers should not have access to these helper data structures
        // This is not great, but we need to make sure that when mapping DTOs to models
        // that these DTOs are accessed on their managed object contexts.
        // So we need to pass the NSManagedObjectContext to the generator.
        generator = { index in
            var element: Element!
            if let context = context {
                context.performAndWait {
                    element = map(source[index])
                }
            } else {
                element = map(source[index])
            }
            return element
        }

        /// This is just an internal test to see how we behave when the DB models are immediately mapped instead of being lazily mapped
        if !StreamRuntimeCheck._isBackgroundMappingEnabled {
            cache = .init(capacity: source.count)
        } else {
            if Thread.isMainThread {
                log.debug("This should not be happening on the Main Thread")
            }
            cache = .init(elements: source.map(map))
        }
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

    public func append(_ element: Element) {
        cache.values.append(element)
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
    public func lazyCachedMap<T>(
        _ transformation: @escaping (Element) -> T,
        context: NSManagedObjectContext? = nil
    ) -> LazyCachedMapCollection<T> {
        .init(source: self, map: transformation, context: context)
    }
}

// Must be class so it can be mutable while the collection isn't
private class Cache<Element> {
    init(capacity: Int) {
        values = ContiguousArray(repeating: nil, count: capacity)
    }

    init(elements: [Element]) {
        values = ContiguousArray(elements)
    }

    var values: ContiguousArray<Element?>
}
