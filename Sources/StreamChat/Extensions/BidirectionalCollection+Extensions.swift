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
    ///   - dropsExisting: A predicate what returns true if its first argument should be dropped before its second argument is inserted to the resulting sorted collection.
    func uniquelyMerged(_ insertedSortedElements: [Element], areInIncreasingOrder: (Element, Element) -> Bool, dropsExisting: (Element, Element) -> Bool) -> [Element] {
        func insert(_ merged: inout [Element], newElement: Element) {
            if let last = merged.last, dropsExisting(last, newElement) {
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
        uniquelyMerged(insertedSortedElements, areInIncreasingOrder: { first, second in first.createdAt < second.createdAt }, dropsExisting: { first, second in first.id == second.id })
    }
    
    func uniquelyApplied(_ changes: [ListChange<Element>]) -> [Element] {
        var removedIds = Set<MessageId>()
        var newSortedElements = [Element]()
        newSortedElements.reserveCapacity(changes.count)
        
        for change in changes {
            if change.isRemove {
                removedIds.insert(change.item.id)
            } else {
                newSortedElements.append(change.item)
            }
        }
                
        newSortedElements = newSortedElements.sort(using: [.init(keyPath: \.createdAt, isAscending: true)])
        return uniquelyMerged(
            newSortedElements,
            areInIncreasingOrder: { $0.createdAt < $1.createdAt },
            dropsExisting: { existing, incoming in
                removedIds.contains(existing.id) || existing.id == incoming.id
            }
        )
    }
}

extension BidirectionalCollection where Element == ChatChannel {
    func uniquelyMerged(_ insertedSortedElements: [Element], sortDescriptors: [NSSortDescriptor]) -> [Element] {
        uniquelyMerged(
            insertedSortedElements,
            areInIncreasingOrder: { sortDescriptors.compare($0, to: $1) == .orderedAscending },
            dropsExisting: { existing, incoming in
                existing.cid == incoming.cid
            }
        )
    }
    
    func uniquelyApplied(_ changes: [ListChange<Element>], sortDescriptors: [NSSortDescriptor]) -> [Element] {
        var removedIds = Set<ChannelId>()
        var updatedSortedChanges = [ListChange<Element>]()
        updatedSortedChanges.reserveCapacity(changes.count)
        
        for change in changes {
            if change.isRemove {
                removedIds.insert(change.item.cid)
            } else {
                updatedSortedChanges.append(change)
            }
        }
        updatedSortedChanges = updatedSortedChanges.sort(using: [.init(keyPath: \.indexPath, isAscending: true)])
        
        return uniquelyMerged(
            updatedSortedChanges.map(\.item),
            areInIncreasingOrder: { sortDescriptors.compare($0, to: $1) == .orderedAscending },
            dropsExisting: { existing, incoming in
                removedIds.contains(existing.cid) || existing.cid == incoming.cid
            }
        )
    }
}

private extension Array where Element == NSSortDescriptor {
    func compare(_ object1: Any, to object2: Any) -> ComparisonResult {
        var result = ComparisonResult.orderedSame
        var index = startIndex
        repeat {
            result = self[index].compare(object1, to: object2)
            index = self.index(after: index)
        } while result == ComparisonResult.orderedSame && index < endIndex
        return result
    }
}
