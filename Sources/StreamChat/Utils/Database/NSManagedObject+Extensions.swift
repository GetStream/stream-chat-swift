//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData

extension NSManagedObject {
    @objc class var entityName: String {
        "\(self)"
    }
}

extension NSManagedObject {
    static func load<T>(by request: NSFetchRequest<T>, context: NSManagedObjectContext) -> [T] {
        do {
            return try context.fetch(request)
        } catch {
            log.error("Could not load \(error), \(error.localizedDescription)")
            return []
        }
    }
}
