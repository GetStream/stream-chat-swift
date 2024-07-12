//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// Read-only collection that applies transformation to element on first access.
///
/// Compared to `LazyMapCollection` does not evaluate the whole collection on `count` call.
public struct LazyCachedMapCollection<Element>: RandomAccessCollection, @unchecked Sendable {
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

    // Create a copy of a given lazy cached map collection.
    // It reuses the same generator and the cache.
    public init(_ collection: LazyCachedMapCollection) {
        // Reuse the generator
        generator = collection.generator
        // Create a new cache instance
        cache = .init(capacity: collection.count)
        // After creating the new cache, refill the existing cached values
        cache.values = collection.cache.values
    }

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

    internal var generator: (Index) -> Element
    internal var cache: Cache<Element>

    public subscript(position: Index) -> Element {
        if let cached = cache.values[position] {
            return cached
        } else {
            let value = generator(position)
            defer { cache.values[position] = value }
            return value
        }
    }

    public mutating func append(_ element: Element) {
        // Even though `LazyCachedMapCollection` is a value type,
        // the `cache` is not, so whenever we append a new value,
        // we need to make sure we are creating a copy.
        self = LazyCachedMapCollection(self)
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

extension LazyCachedMapCollection {
    init<Collection: RandomAccessCollection, SourceElement: NSManagedObject>(
        source: Collection,
        itemCreator: @escaping (SourceElement) throws -> Element,
        sorting: [SortValue<Element>] = [],
        context: NSManagedObjectContext
    ) where Collection.Element == SourceElement, Collection.Index == Index {
        let transformDtoToModel: (SourceElement) -> Element = { dto in
            var resultItem: Element!
            do {
                resultItem = try itemCreator(dto)
            } catch {
                log.assertionFailure("Unable to convert a DB entity to model: \(error.localizedDescription)")
            }
            return resultItem
        }
        // Since post FRC sorting is defined using mapped types, then we are required to map all the elements right now
        if !sorting.isEmpty {
            var sortedElements: [Element]!
            context.performAndWait {
                sortedElements = source
                    .map(transformDtoToModel)
                    .sort(using: sorting)
            }
            self.init(
                source: sortedElements,
                map: { $0 },
                context: nil // nil for skipping performAndWait later when accessing elements
            )
        } else {
            self.init(
                source: source,
                map: transformDtoToModel,
                context: context
            )
        }
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
extension LazyCachedMapCollection {
    class Cache<Value> {
        init(capacity: Int) {
            values = ContiguousArray(repeating: nil, count: capacity)
        }

        init(elements: [Value]) {
            values = ContiguousArray(elements)
        }

        var values: ContiguousArray<Value?>
    }
}
