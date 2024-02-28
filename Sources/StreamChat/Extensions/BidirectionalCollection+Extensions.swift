//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension BidirectionalCollection {
    /// Merges sorted elements into a sorted collection.
    ///
    /// - Parameters:
    ///   - newElements: A collection for sorted elements to be inserted.
    ///   - areInIncreasingOrder: A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    ///   - unique: True, if both elements are unique, false if equal.
    func uniquelyMerged(_ insertedSortedElements: [Element], areInIncreasingOrder: (Element, Element) -> Bool, unique: (Element, Element) -> Bool) -> [Element] {
        func insert(_ merged: inout [Element], newElement: Element) {
            if let last = merged.last, !unique(last, newElement) {
                merged.removeLast()
            }
            merged.append(newElement)
        }

        var merged = [Element]()
        merged.reserveCapacity(count + insertedSortedElements.count)
        
        var currentElementIndex = startIndex
        var newElementIndex = insertedSortedElements.startIndex
        while currentElementIndex < endIndex, newElementIndex < insertedSortedElements.endIndex {
            if areInIncreasingOrder(self[currentElementIndex], insertedSortedElements[newElementIndex]) {
                insert(&merged, newElement: self[currentElementIndex])
                currentElementIndex = index(after: currentElementIndex)
            } else {
                insert(&merged, newElement: insertedSortedElements[newElementIndex])
                newElementIndex = insertedSortedElements.index(after: newElementIndex)
            }
        }
        while currentElementIndex < endIndex {
            insert(&merged, newElement: self[currentElementIndex])
            currentElementIndex = index(after: currentElementIndex)
        }
        while newElementIndex < insertedSortedElements.endIndex {
            insert(&merged, newElement: insertedSortedElements[newElementIndex])
            newElementIndex = insertedSortedElements.index(after: newElementIndex)
        }
        return merged
    }
}

extension BidirectionalCollection where Element == ChatMessage {
    func uniquelyMerged(_ insertedSortedElements: [Element]) -> [Element] {
        uniquelyMerged(insertedSortedElements, areInIncreasingOrder: { first, second in first.createdAt < second.createdAt }, unique: { first, second in first.id != second.id })
    }
}
