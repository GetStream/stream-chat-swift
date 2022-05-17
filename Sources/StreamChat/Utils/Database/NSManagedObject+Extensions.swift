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
    class func insertNewObject<T: NSManagedObject>(
        into context: NSManagedObjectContext,
        for request: NSFetchRequest<T>
    ) -> T {
        let entity = insertNewObject(forEntityName: T.entityName, into: context)
        request.entity = NSEntityDescription.entity(forEntityName: T.entityName, in: context)!
        FetchCache.shared.set(request, objectIds: [entity.objectID])
        return entity as! T
    }
}

protocol NSFetchRequestGettable {}

private let idKey = "id"

extension NSFetchRequestGettable where Self: NSManagedObject {
    static func fetchRequest(id: String) -> NSFetchRequest<Self> {
        fetchRequest(keyPath: idKey, equalTo: id)
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
        load(keyPath: idKey, equalTo: id, context: context)
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
    fileprivate static let shared = FetchCache()
    private let queue = DispatchQueue(label: "io.stream.com.fetch-cache", qos: .userInitiated)
    private var cache = [NSFetchRequest<NSFetchRequestResult>: [NSManagedObjectID]]()

    fileprivate func set<T>(_ request: NSFetchRequest<T>, objectIds: [NSManagedObjectID]) where T: NSFetchRequestResult {
        guard let request = request as? NSFetchRequest<NSFetchRequestResult> else {
            log.assertionFailure("Request should have a generic type conforming to NSFetchRequestResult")
            return
        }
        queue.sync {
            cache[request] = objectIds
        }
    }
    
    fileprivate func get<T>(_ request: NSFetchRequest<T>) -> [NSManagedObjectID]? where T: NSFetchRequestResult {
        guard let request = request as? NSFetchRequest<NSFetchRequestResult> else {
            log.assertionFailure("Request should have a generic type conforming to NSFetchRequestResult")
            return nil
        }
        var objectIDs: [NSManagedObjectID]?
        queue.sync {
            objectIDs = cache[request]
        }
        return objectIDs
    }
    
    static func clear() {
        Self.shared.cache.removeAll()
    }

    private func clear() {
        queue.sync {
            cache.removeAll()
        }
    }
}

extension PerformanceMeasureItem {
    static let fetch = Self("fetch")
}

import OSLog

extension NSManagedObjectContext {
    func fetch<T>(_ request: NSFetchRequest<T>, using cache: FetchCache) throws -> [T] where T: NSFetchRequestResult {
        // log.startMeasuring(item: .fetch, "%s", String(describing: T.self))
        if #available(iOSApplicationExtension 12.0, *) {
            os_signpost(.begin, log: log.osLogHandler, name: PerformanceMeasureItem.fetch.name, "%s", request.entityName!)
        }
        if let objectIds = cache.get(request) {
            // We have `fetch`ed this request before
            if !objectIds.isEmpty {
                // ..and we've found the ids
                do {
                    let dtos = try objectIds.map { try existingObject(with: $0) as! T }
                    log.endMeasuring(item: .fetch, "cache hit, existingObject")
                    return dtos
                } catch {
                    throw error
                }
            } else {
                // ..and it's not in DB
                log.endMeasuring(item: .fetch, "cache hit, not in DB")
                return []
            }
        } else {
            // We haven't `fetch`ed the request yet
            let objects = try fetch(request)
            let objectIds = objects.map { ($0 as! NSManagedObject).objectID }
            cache.set(request, objectIds: objectIds)
            // log.endMeasuring(item: .fetch, "cache miss, found %d objects in DB", objectIds.count)
            if #available(iOSApplicationExtension 12.0, *) {
                os_signpost(
                    .end,
                    log: log.osLogHandler,
                    name: PerformanceMeasureItem.fetch.name,
                    "cache miss, found %d objects in DB",
                    objectIds.count
                )
            }
            return objects
        }
    }
}
