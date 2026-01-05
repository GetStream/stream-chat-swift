//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A collection wrapping the base collection which allows base collections of different types.
///
/// - Note: The type of the base collection can change in the future.
public struct StreamCollection<Element>: RandomAccessCollection {
    public typealias Index = Int

    private let _endIndex: () -> Index
    private let _position: (Index) -> Element
    private let _startIndex: () -> Index

    /// Creates an instance of the collection using the base collection as the data source.
    public init<BaseCollection>(_ baseCollection: BaseCollection) where BaseCollection: RandomAccessCollection, BaseCollection.Element == Element, BaseCollection.Index == Index {
        _endIndex = { baseCollection.endIndex }
        _position = { baseCollection[$0] }
        _startIndex = { baseCollection.startIndex }
    }

    /// The position of the first element in a non-empty collection.
    public var startIndex: Index { _startIndex() }
    
    /// The collection's “past the end” position—that is, the position one greater than the last valid subscript argument.
    public var endIndex: Index { _endIndex() }
    
    /// Accesses the element at the specified position.
    public subscript(position: Index) -> Element {
        _position(position)
    }
}

extension StreamCollection: CustomStringConvertible {
    public var description: String {
        let contents = map { String(describing: $0) }.joined(separator: ", ")
        return "\(Self.self)(\(contents))"
    }
}
