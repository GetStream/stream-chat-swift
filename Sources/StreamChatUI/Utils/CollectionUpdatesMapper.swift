//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The verification of conflicts is just a temporary solution
/// until the root cause of the conflicts has been solved.
final class CollectionUpdatesMapper {
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
    
    /// Verify if there are conflicts in changes and if there are call `onConflict`
    /// - Parameters:
    ///   - changes: changes
    /// - Returns: Returns the indices mapped to sets. Returns nil if there were conflicts.
    func mapToSetsOfIndexPaths<Item>(
        changes: [ListChange<Item>]
    ) -> Indexes? {
        var allIndexes = Set<IndexPath>()
        var moveIndexes = Set<IndexPathMove>()
        var insertIndexes = Set<IndexPath>()
        var removeIndexes = Set<IndexPath>()
        var updateIndexes = Set<IndexPath>()
        
        var hasConflicts = false
        let verifyConflict = { (indexPath: IndexPath) in
            let (inserted, _) = allIndexes.insert(indexPath)
            hasConflicts = !inserted || hasConflicts
        }
        
        for change in changes {
            if hasConflicts {
                break
            }
            
            switch change {
            case let .insert(_, index):
                verifyConflict(index)
                insertIndexes.insert(index)
            case let .move(_, fromIndex, toIndex):
                verifyConflict(fromIndex)
                verifyConflict(toIndex)
                moveIndexes.insert(IndexPathMove(fromIndex, toIndex))
            case let .remove(_, index):
                verifyConflict(index)
                removeIndexes.insert(index)
            case let .update(_, index):
                verifyConflict(index)
                updateIndexes.insert(index)
            }
        }
        
        if hasConflicts {
            return nil
        }
        
        return (
            move: moveIndexes,
            insert: insertIndexes,
            remove: removeIndexes,
            update: updateIndexes
        )
    }
}
