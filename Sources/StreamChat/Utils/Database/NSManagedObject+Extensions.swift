//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData

extension NSManagedObject {
    @objc class var entityName: String {
        "\(self)"
    }
}

extension NSEntityDescription {
    class func insertNewObject<T: NSFetchRequestResult>(
        forEntityName entityName: String,
        into context: NSManagedObjectContext,
        forRequest request: NSFetchRequest<T>,
        cachingInto cache: FetchCache
    ) -> NSManagedObject {
        let entity = insertNewObject(forEntityName: entityName, into: context)
        cache.set(request, objectIds: [entity.objectID])
        return entity
    }
}

protocol NSFetchRequestGettable {}

extension NSFetchRequestGettable where Self: NSManagedObject {
    static func fetchRequest(id: String) -> NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        return request
    }
    
    static func fetchRequest(keyPath: String, equalTo value: String) -> NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.predicate = NSPredicate(format: "%K == %@", keyPath, value)
        return request
    }
}

extension NSManagedObject: NSFetchRequestGettable {}

extension NSManagedObject {
    static func load<T: NSManagedObject>(by id: String, context: NSManagedObjectContext) -> [T] {
        load(keyPath: "id", equalTo: id, context: context)
    }
    
    static func load<T: NSManagedObject>(keyPath: String, equalTo value: String, context: NSManagedObjectContext) -> [T] {
        let request = NSFetchRequest<T>(entityName: entityName)
        request.predicate = NSPredicate(format: "%K == %@", keyPath, value)
        return load(by: request, context: context)
    }
    
    static func load<T>(by request: NSFetchRequest<T>, context: NSManagedObjectContext) -> [T] {
        request.entity = NSEntityDescription.entity(forEntityName: entityName, in: context)!
        do {
            return try context.fetch(
                request,
                using: FetchCache.shared
            )
        } catch {
            log.error("Could not load \(error), \(error.localizedDescription)")
            return []
        }
    }
}

class FetchCache {
    static let shared = FetchCache()
    
    private var cache = [NSFetchRequest<NSFetchRequestResult>: [NSManagedObjectID]]()
    
    func set<T>(_ request: NSFetchRequest<T>, objectIds: [NSManagedObjectID]) where T: NSFetchRequestResult {
        cache[request as! NSFetchRequest<NSFetchRequestResult>] = objectIds
    }
    
    func get<T>(_ request: NSFetchRequest<T>) -> [NSManagedObjectID]? where T: NSFetchRequestResult {
        cache[request as! NSFetchRequest<NSFetchRequestResult>]
    }
    
    func clear() {
        cache.removeAll()
    }
}

extension NSManagedObjectContext {
    func fetch<T>(_ request: NSFetchRequest<T>, using cache: FetchCache) throws -> [T] where T: NSFetchRequestResult {
        if let objectIds = cache.get(request) {
            // We have `fetch`ed this request before
            if !objectIds.isEmpty {
                // ..and we've found the ids
                return try objectIds.map { try existingObject(with: $0) as! T }
            } else {
                // ..and it's not in DB
                return []
            }
        } else {
            // We haven't `fetch`ed the request yet
            let objects = try fetch(request)
            let objectIds = objects.map { ($0 as! NSManagedObject).objectID }
            cache.set(request, objectIds: objectIds)
            return objects
        }
    }
}
