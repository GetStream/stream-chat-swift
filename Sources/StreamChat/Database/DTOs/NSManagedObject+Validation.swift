//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

extension NSManagedObject {
    var isValid: Bool {
        guard let context = managedObjectContext else { return false }
        do {
            _ = try context.existingObject(with: objectID)
        } catch {
            return false
        }
        return true
    }
}
