//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// A protocol marking an DTO object containing ephemeral values, i.e. user online state, or unread counts. These values
/// need to be reset every time the database is initialized.
@objc protocol EphemeralValuesContainer {
    /// Resets the ephemeral relationship values of the container to their default state.
    static func resetEphemeralRelationshipValues(in context: NSManagedObjectContext)
    
    /// Returns batch update request for resetting non-relationship properties.
    static func resetEphemeralValuesBatchRequests() -> [NSBatchUpdateRequest]
}
