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
    static func load<T: NSManagedObject>(ids: Set<String>, context: NSManagedObjectContext) -> [T] {
        let request = NSFetchRequest<T>(entityName: entityName)
        request.predicate = NSPredicate(format: "id IN %@", ids)
        return load(by: request, context: context)
    }
    
    static func load<T: NSManagedObject>(by id: String, fetch: Bool, context: NSManagedObjectContext) -> [T] {
        if !fetch {
            if let dto = PrefetchStorage.shared.prefetchedObjects[id] as? T {
                return [dto]
            }
            return []
        }
        return load(by: id, context: context)
    }
    
    static func load<T: NSManagedObject>(by id: String, context: NSManagedObjectContext) -> [T] {
        let request = NSFetchRequest<T>(entityName: entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        return load(by: request, context: context)
    }
    
    static func load<T>(by request: NSFetchRequest<T>, context: NSManagedObjectContext) -> [T] {
        do {
            return try context.fetch(request)
        } catch {
            log.error("Could not load \(error), \(error.localizedDescription)")
            return []
        }
    }
}
