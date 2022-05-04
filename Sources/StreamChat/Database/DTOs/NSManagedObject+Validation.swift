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

struct InvalidModel: LocalizedError {
    let id: NSManagedObjectID
    let entityName: String?

    init(_ model: NSManagedObject) {
        id = model.objectID
        entityName = model.entity.name
    }

    var errorDescription: String? {
        "\(entityName ?? "Unknown") object with ID \(id) is invalid"
    }
}
