//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData

public extension NSManagedObject {
    /// Shortcut for transfering objects between contexts
    ///
    /// Returns implicitly unwrapped optional as it is possible for this operation to fail,
    /// this extension is **intended to be used in tests** so it should not be an issue
    func inContext(_ context: NSManagedObjectContext) -> Self! {
        context.object(with: objectID) as? Self
    }
}
