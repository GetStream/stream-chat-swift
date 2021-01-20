//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// Assigns the new value given for the entity's keyPath only if it's different.
///
/// This function is used mainly for updating NSManagedObject's properties.
/// Since updating an NSManagedObject's property with the same value
/// produces an update notification, we use this to avoid that case, and avoid unnecessary updates.
///
/// - Parameters:
///   - entity: Entity to be updated
///   - keyPath: Entity's keyPath to be updated.
///   - newValue: New value for the entity
func assignIfDifferent<Root: AnyObject, Value: Equatable>(
    _ entity: Root,
    _ keyPath: ReferenceWritableKeyPath<Root, Value>,
    _ newValue: Value
) {
    if entity[keyPath: keyPath] != newValue {
        entity[keyPath: keyPath] = newValue
    }
}
