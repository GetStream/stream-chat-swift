//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// Converts database models to immutable value types by reusing existing items.
enum DatabaseItemConverter {
    /// Convert database models by reusing existing unchanged items.
    /// - Parameters:
    ///   - dtos: A list of DTOs in the NSFetchedResultsController.
    ///   - existing: A list of existing items.
    ///   - changes: List changes reported by the NSFetchedResultsController.
    ///   - itemCreator: A closure which converts database models.
    ///   - itemReuseKeyPaths: A pair of keypaths used for matching database models to existing items.
    ///   - sorting: A list of sort values for sorting items outside of NSFetchedResultsController.
    ///   - checkCancellation: A closure called before each invocation of the `itemCreator`. If true, no more models are converted.
    /// - Returns: Returns a list of immutable models by reusing existing unchanged models.
    static func convert<Item, DTO>(
        dtos: [DTO],
        existing: [Item],
        changes: [ListChange<Item>]?,
        itemCreator: (DTO) throws -> Item,
        itemReuseKeyPaths: (item: KeyPath<Item, String>, dto: KeyPath<DTO, String>)?,
        sorting: [SortValue<Item>],
        checkCancellation: () -> Bool
    ) -> [Item] where DTO: NSManagedObject {
        let items: [Item]
        
        // Reuse converted items by id
        if StreamRuntimeCheck._isDatabaseObserverItemReusingEnabled, let itemReuseKeyPaths, !existing.isEmpty {
            let existingItems = existing.map { ($0[keyPath: itemReuseKeyPaths.item], $0) }
            var lookup = Dictionary(existingItems, uniquingKeysWith: { _, second in second })
            // Changes contains newly converted items, add them to the lookup
            changes?
                .map(\.item)
                .forEach { updatedItem in
                    let key = updatedItem[keyPath: itemReuseKeyPaths.item]
                    lookup[key] = updatedItem
                }
            items = dtos.compactMap { dto in
                if let existing = lookup[dto[keyPath: itemReuseKeyPaths.dto]] {
                    return existing
                }
                guard !checkCancellation() else { return nil }
                return try? itemCreator(dto)
            }
        } else {
            items = dtos.compactMap { dto in
                guard !checkCancellation() else { return nil }
                return try? itemCreator(dto)
            }
        }
        return sorting.isEmpty ? items : items.sort(using: sorting)
    }
}
