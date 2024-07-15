//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// An ordered, random-access collection.
///
/// - Important: `LazyCachedMapCollection` used to be a lazy collection applying transformations on the first element access. Since SDK version 4.60.0 it is not lazy anymore and works the same way as the Swift's Array type.
public struct LazyCachedMapCollection<Element>: RandomAccessCollection {
    public typealias Index = Int

    public func index(before i: Index) -> Index {
        mappedElements.index(before: i)
    }

    public func index(after i: Index) -> Index {
        mappedElements.index(after: i)
    }

    public var startIndex: Index { mappedElements.startIndex }

    public var endIndex: Index { mappedElements.endIndex }

    public var count: Index { mappedElements.count }

    public init(_ collection: LazyCachedMapCollection) {
        mappedElements = collection.mappedElements
    }
    
    private var mappedElements: [Element]
    
    init(elements: [Element]) {
        mappedElements = elements
    }

    public init<Collection: RandomAccessCollection, SourceElement>(
        source: Collection,
        map: @escaping (SourceElement) -> Element,
        context: NSManagedObjectContext? = nil
    ) where Collection.Element == SourceElement, Collection.Index == Index {
        mappedElements = source.map(map)
    }

    public subscript(position: Index) -> Element {
        mappedElements[position]
    }

    public mutating func append(_ element: Element) {
        mappedElements.append(element)
    }
}

extension LazyCachedMapCollection: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Element

    public init(arrayLiteral elements: Element...) {
        mappedElements = elements
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
