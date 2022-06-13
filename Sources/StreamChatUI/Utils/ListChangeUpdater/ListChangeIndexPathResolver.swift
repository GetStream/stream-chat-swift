//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Component responsible to map ListChange's to IndexPaths.
/// It also verifies if there is any conflict.
final class ListChangeIndexPathResolver {
    struct IndexPathMove: Hashable, CustomStringConvertible {
        var fromIndex: IndexPath
        var toIndex: IndexPath
        
        init(_ from: IndexPath, _ to: IndexPath) {
            fromIndex = from
            toIndex = to
        }
        
        var description: String {
            "(from: \(fromIndex), to: \(toIndex))"
        }
    }
    
    typealias Indexes = (
        move: Set<IndexPathMove>,
        insert: Set<IndexPath>,
        remove: Set<IndexPath>,
        update: Set<IndexPath>
    )
    
    /// Maps `ListChange`s to index paths and checks if there is any conflict.
    /// - Parameters:
    ///   - changes: changes
    /// - Returns: Returns the indices mapped to sets. Returns nil if there were conflicts.
    func resolve<Item>(
        changes: [ListChange<Item>]
    ) -> Indexes? {
        var moveFromIndexes = Set<IndexPath>()
        var moveToIndexes = Set<IndexPath>()
        var moveIndexes = Set<IndexPathMove>()
        var insertIndexes = Set<IndexPath>()
        var removeIndexes = Set<IndexPath>()
        var updateIndexes = Set<IndexPath>()
        
        for change in changes {
            switch change {
            case let .insert(_, index):
                insertIndexes.insert(index)
            case let .move(_, fromIndex, toIndex):
                moveIndexes.insert(IndexPathMove(fromIndex, toIndex))
                moveFromIndexes.insert(fromIndex)
                moveToIndexes.insert(toIndex)
            case let .remove(_, index):
                removeIndexes.insert(index)
            case let .update(_, index):
                updateIndexes.insert(index)
            }
        }

        let indexes = Indexes(
            move: moveIndexes,
            insert: insertIndexes,
            remove: removeIndexes,
            update: updateIndexes
        )

        // Check if there are conflicts between Inserts<->Moves<->Deletes or Updates<->Moves<->Deletes.
        // We don't check for conflicts between Inserts<->Updates, since it is not a conflict.
        let movesAndRemoves = [moveFromIndexes, moveToIndexes, removeIndexes]
        let hasInsertConflicts = insertIndexes.containsDuplicates(between: movesAndRemoves)
        let hasUpdateConflicts = updateIndexes.containsDuplicates(between: movesAndRemoves)
        let hasConflicts = hasInsertConflicts || hasUpdateConflicts
        if hasConflicts {
            log.warning("ListChange conflicts found: \(indexes)")
            return nil
        }
        
        return indexes
    }
}

private extension Set where Element == IndexPath {
    // If the count of all elements before the sets are merged is different from the count of the elements
    // after the sets are merged, then it means there are duplicates between the provided sets.
    //
    // Example of a conflict:
    // ["1", "2", "3"] + ["4", "5", "6"] + ["1", "8", "9"] = 9
    // ["1", "2", "3", "4", "5", "6", "8", "9"] = 8
    func containsDuplicates(between sets: [Self]) -> Bool {
        let allElements = sets.reduce(Array(self), +)
        let mergedElements = Set(allElements)
        return allElements.count != mergedElements.count
    }
}
