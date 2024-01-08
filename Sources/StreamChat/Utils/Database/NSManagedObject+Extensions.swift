//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        let obj = T(context: context)
        request.entity = obj.entity
        FetchCache.shared.set(request, objectIds: [obj.objectID])
        return obj
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

    static func load<T: NSManagedObject>(by request: NSFetchRequest<T>, context: NSManagedObjectContext) -> [T] {
        request.entity = NSEntityDescription.entity(forEntityName: T.entityName, in: context)!
        do {
            return try context.fetch(request, using: FetchCache.shared)
        } catch {
            log.error("Could not load \(error), \(error.localizedDescription)")
            return []
        }
    }
}

class FetchCache {
    /// We use this wrapper to have a custom implementation of both Equatable and Hashable.
    /// This is because when using NSFetchRequest directly, its implementation of `hash` uses `entity`, which is a property that crashes on access
    /// when it is not yet set
    struct FetchRequestWrapper<T: NSFetchRequestResult>: Equatable, Hashable {
        let request: NSFetchRequest<T>

        static func == (lhs: FetchRequestWrapper<T>, rhs: FetchRequestWrapper<T>) -> Bool {
            switch (lhs.request.predicate, rhs.request.predicate) {
            case let (.some(lhsPredicate), .some(rhsPredicate)) where lhsPredicate == rhsPredicate:
                break
            case (.none, .none):
                break
            default:
                return false
            }

            return lhs.request.sortDescriptors == rhs.request.sortDescriptors
                && lhs.request.entityName == rhs.request.entityName
                && lhs.request.fetchLimit == rhs.request.fetchLimit
        }

        func hash(into hasher: inout Hasher) {
            if let predicate = request.predicate {
                hasher.combine(predicate)
            }
            if let sortDescriptors = request.sortDescriptors {
                sortDescriptors.forEach {
                    hasher.combine($0.key)
                    hasher.combine($0.ascending)
                }
            }
            if let entityName = request.entityName {
                hasher.combine(entityName)
            }
            hasher.combine(request.fetchLimit)
        }
    }

    fileprivate static let shared = FetchCache()
    private let queue = DispatchQueue(label: "io.stream.com.fetch-cache", qos: .userInitiated, attributes: .concurrent)
    private var cache = [FetchRequestWrapper<NSFetchRequestResult>: [NSManagedObjectID]]()

    var cacheEntriesCount: Int {
        queue.sync { cache.count }
    }

    func set<T>(_ request: NSFetchRequest<T>, objectIds: [NSManagedObjectID]) where T: NSFetchRequestResult {
        guard let request = request as? NSFetchRequest<NSFetchRequestResult> else {
            log.assertionFailure("Request should have a generic type conforming to NSFetchRequestResult")
            return
        }

        let wrapper = FetchRequestWrapper(request: request)
        queue.async(flags: .barrier) {
            self.cache[wrapper] = objectIds
        }
    }

    func get<T>(_ request: NSFetchRequest<T>) -> [NSManagedObjectID]? where T: NSFetchRequestResult {
        guard let request = request as? NSFetchRequest<NSFetchRequestResult> else {
            log.assertionFailure("Request should have a generic type conforming to NSFetchRequestResult")
            return nil
        }
        let wrapper = FetchRequestWrapper(request: request)
        var objectIDs: [NSManagedObjectID]?
        queue.sync {
            objectIDs = cache[wrapper]
        }
        return objectIDs
    }

    static func clear() {
        Self.shared.clear()
    }

    private func clear() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
}

extension NSManagedObjectContext {
    func fetch<T>(_ request: NSFetchRequest<T>, using cache: FetchCache) throws -> [T] where T: NSFetchRequestResult {
        if let objectIds = cache.get(request), !objectIds.contains(where: { $0.isTemporaryID }) {
            return try objectIds.compactMap { try existingObject(with: $0) as? T }
        }

        // We haven't `fetch`ed the request yet
        let objects = try fetch(request)
        let objectIds = objects.compactMap { ($0 as? NSManagedObject)?.objectID }
        cache.set(request, objectIds: objectIds)
        return objects
    }
}
