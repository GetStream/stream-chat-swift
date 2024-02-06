//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit

//
// These are customized reload functions from DiffereceKit which use reconfigureItems and reconfigureRows.
// We can remove this file when DifferenceKit switches to reconfigure instead of reload.
// Reconfiguring gives a noticable performance boost since cells are not recreated.
//

extension UITableView {
    /// Applies multiple animated updates in stages using `StagedChangeset`.
    ///
    /// - Note: There are combination of changes that crash when applied simultaneously in `performBatchUpdates`.
    ///         Assumes that `StagedChangeset` has a minimum staged changesets to avoid it.
    ///         The data of the data-source needs to be updated synchronously before `performBatchUpdates` in every stages.
    ///
    /// - Parameters:
    ///   - stagedChangeset: A staged set of changes.
    ///   - animation: An option to animate the updates.
    ///   - reconfigure: A closure that takes an index path as its argument and if it returns `true`, cells are reconfigured, otherwise cells are reloaded
    ///   - interrupt: A closure that takes an changeset as its argument and returns `true` if the animated
    ///                updates should be stopped and performed reloadData. Default is nil.
    ///   - setData: A closure that takes the collection as a parameter.
    ///              The collection should be set to data-source of UITableView.
    ///   - completion: A completion handler block to execute when all of the operations finish. This block takes a single Boolean parameter that contains the value true if all of the related animations completed successfully or false if they were interrupted.
    func reload<C>(
        using stagedChangeset: StagedChangeset<C>,
        with animation: @autoclosure () -> RowAnimation,
        reconfigure: (IndexPath) -> Bool,
        interrupt: ((Changeset<C>) -> Bool)? = nil,
        setData: (C) -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        reload(
            using: stagedChangeset,
            deleteSectionsAnimation: animation(),
            insertSectionsAnimation: animation(),
            reloadSectionsAnimation: animation(),
            deleteRowsAnimation: animation(),
            insertRowsAnimation: animation(),
            reloadRowsAnimation: animation(),
            reconfigure: reconfigure,
            interrupt: interrupt,
            setData: setData,
            completion: completion
        )
    }
    
    /// Applies multiple animated updates in stages using `StagedChangeset`.
    ///
    /// - Note: There are combination of changes that crash when applied simultaneously in `performBatchUpdates`.
    ///         Assumes that `StagedChangeset` has a minimum staged changesets to avoid it.
    ///         The data of the data-source needs to be updated synchronously before `performBatchUpdates` in every stages.
    ///
    /// - Parameters:
    ///   - stagedChangeset: A staged set of changes.
    ///   - deleteSectionsAnimation: An option to animate the section deletion.
    ///   - insertSectionsAnimation: An option to animate the section insertion.
    ///   - reloadSectionsAnimation: An option to animate the section reload.
    ///   - deleteRowsAnimation: An option to animate the row deletion.
    ///   - insertRowsAnimation: An option to animate the row insertion.
    ///   - reloadRowsAnimation: An option to animate the row reload.
    ///   - reconfigure: A closure that takes an index path as its argument and if it returns `true`, cells are reconfigured, otherwise cells are reloaded
    ///   - interrupt: A closure that takes an changeset as its argument and returns `true` if the animated
    ///                updates should be stopped and performed reloadData. Default is nil.
    ///   - setData: A closure that takes the collection as a parameter.
    ///              The collection should be set to data-source of UITableView.
    ///   - completion: A completion handler block to execute when all of the operations finish. This block takes a single Boolean parameter that contains the value true if all of the related animations completed successfully or false if they were interrupted.
    func reload<C>(
        using stagedChangeset: StagedChangeset<C>,
        deleteSectionsAnimation: @autoclosure () -> RowAnimation,
        insertSectionsAnimation: @autoclosure () -> RowAnimation,
        reloadSectionsAnimation: @autoclosure () -> RowAnimation,
        deleteRowsAnimation: @autoclosure () -> RowAnimation,
        insertRowsAnimation: @autoclosure () -> RowAnimation,
        reloadRowsAnimation: @autoclosure () -> RowAnimation,
        reconfigure: (IndexPath) -> Bool = { _ in false },
        interrupt: ((Changeset<C>) -> Bool)? = nil,
        setData: (C) -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        if case .none = window, let data = stagedChangeset.last?.data {
            setData(data)
            reloadData()
            completion?(true)
            return
        }
        
        for changeset in stagedChangeset {
            if let interrupt = interrupt, interrupt(changeset), let data = stagedChangeset.last?.data {
                setData(data)
                reloadData()
                completion?(true)
                return
            }
            
            performBatchUpdates({
                setData(changeset.data)
                
                if !changeset.sectionDeleted.isEmpty {
                    deleteSections(IndexSet(changeset.sectionDeleted), with: deleteSectionsAnimation())
                }
                
                if !changeset.sectionInserted.isEmpty {
                    insertSections(IndexSet(changeset.sectionInserted), with: insertSectionsAnimation())
                }
                
                if !changeset.sectionUpdated.isEmpty {
                    reloadSections(IndexSet(changeset.sectionUpdated), with: reloadSectionsAnimation())
                }
                
                for (source, target) in changeset.sectionMoved {
                    moveSection(source, toSection: target)
                }
                
                if !changeset.elementDeleted.isEmpty {
                    deleteRows(at: changeset.elementDeleted.map { IndexPath(row: $0.element, section: $0.section) }, with: deleteRowsAnimation())
                }
                
                if !changeset.elementInserted.isEmpty {
                    insertRows(at: changeset.elementInserted.map { IndexPath(row: $0.element, section: $0.section) }, with: insertRowsAnimation())
                }
                
                if !changeset.elementUpdated.isEmpty {
                    var indexPaths = changeset.elementUpdated.map { IndexPath(row: $0.element, section: $0.section) }
                    if #available(iOS 15.0, *) {
                        let partitioned = indexPaths.partitionReconfigurable(by: reconfigure)
                        if !partitioned.reconfiguredIndexPaths.isEmpty {
                            reconfigureRows(at: partitioned.reconfiguredIndexPaths)
                        }
                        if !partitioned.reloadedIndexPaths.isEmpty {
                            reloadRows(at: partitioned.reloadedIndexPaths, with: reloadRowsAnimation())
                        }
                    } else {
                        reloadRows(at: indexPaths, with: reloadRowsAnimation())
                    }
                }
                
                for (source, target) in changeset.elementMoved {
                    moveRow(at: IndexPath(row: source.element, section: source.section), to: IndexPath(row: target.element, section: target.section))
                }
            }, completion: completion)
        }
    }
}

extension UICollectionView {
    /// Applies multiple animated updates in stages using `StagedChangeset`.
    ///
    /// - Note: There are combination of changes that crash when applied simultaneously in `performBatchUpdates`.
    ///         Assumes that `StagedChangeset` has a minimum staged changesets to avoid it.
    ///         The data of the data-source needs to be updated synchronously before `performBatchUpdates` in every stages.
    ///
    /// - Parameters:
    ///   - stagedChangeset: A staged set of changes.
    ///   - reconfigure: A closure that takes an index path as its argument and if it returns `true`, cells are reconfigured, otherwise cells are reloaded
    ///   - interrupt: A closure that takes an changeset as its argument and returns `true` if the animated
    ///                updates should be stopped and performed reloadData. Default is nil.
    ///   - setData: A closure that takes the collection as a parameter.
    ///              The collection should be set to data-source of UICollectionView.
    ///   - completion: A completion handler block to execute when all of the operations finish. This block takes a single Boolean parameter that contains the value true if all of the related animations completed successfully or false if they were interrupted.
    func reload<C>(
        using stagedChangeset: StagedChangeset<C>,
        reconfigure: (IndexPath) -> Bool,
        interrupt: ((Changeset<C>) -> Bool)? = nil,
        setData: (C) -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        if case .none = window, let data = stagedChangeset.last?.data {
            setData(data)
            reloadData()
            completion?(true)
            return
        }
        
        for changeset in stagedChangeset {
            if let interrupt = interrupt, interrupt(changeset), let data = stagedChangeset.last?.data {
                setData(data)
                reloadData()
                completion?(true)
                return
            }
            
            performBatchUpdates({
                setData(changeset.data)
                
                if !changeset.sectionDeleted.isEmpty {
                    deleteSections(IndexSet(changeset.sectionDeleted))
                }
                
                if !changeset.sectionInserted.isEmpty {
                    insertSections(IndexSet(changeset.sectionInserted))
                }
                
                if !changeset.sectionUpdated.isEmpty {
                    reloadSections(IndexSet(changeset.sectionUpdated))
                }
                
                for (source, target) in changeset.sectionMoved {
                    moveSection(source, toSection: target)
                }
                
                if !changeset.elementDeleted.isEmpty {
                    deleteItems(at: changeset.elementDeleted.map { IndexPath(item: $0.element, section: $0.section) })
                }
                
                if !changeset.elementInserted.isEmpty {
                    insertItems(at: changeset.elementInserted.map { IndexPath(item: $0.element, section: $0.section) })
                }
                
                if !changeset.elementUpdated.isEmpty {
                    var indexPaths = changeset.elementUpdated.map { IndexPath(row: $0.element, section: $0.section) }
                    
                    if #available(iOS 15.0, *) {
                        let partitioned = indexPaths.partitionReconfigurable(by: reconfigure)
                        if !partitioned.reconfiguredIndexPaths.isEmpty {
                            reconfigureItems(at: partitioned.reconfiguredIndexPaths)
                        }
                        if !partitioned.reloadedIndexPaths.isEmpty {
                            reloadItems(at: partitioned.reloadedIndexPaths)
                        }
                    } else {
                        reloadItems(at: indexPaths)
                    }
                }
                
                for (source, target) in changeset.elementMoved {
                    moveItem(at: IndexPath(item: source.element, section: source.section), to: IndexPath(item: target.element, section: target.section))
                }
            }, completion: completion)
        }
    }
}

private extension Array where Element == IndexPath {
    mutating func partitionReconfigurable(by reconfigurable: (Element) -> Bool) -> (reloadedIndexPaths: [Element], reconfiguredIndexPaths: [Element]) {
        let reconfigureFirstIndex = partition(by: reconfigurable)
        return (Array(self[..<reconfigureFirstIndex]), Array(self[reconfigureFirstIndex...]))
    }
}

#endif
