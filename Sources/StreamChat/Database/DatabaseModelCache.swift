//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

final class DatabaseModelCache {
    private var users = [NSManagedObjectID: ChatUser]()
    
    private(set) var cacheMisses = 0
    private(set) var cacheHits = 0
    
    func user(for dto: UserDTO) -> ChatUser? {
        guard dto.canUseCached else {
            cacheMisses += 1
            return nil
        }
        if let user = users[dto.objectID] {
            cacheHits += 1
            return user
        }
        cacheMisses += 1
        return nil
    }
    
    func setUser(_ user: ChatUser, forObjectID objectId: NSManagedObjectID) {
        users[objectId] = user
    }
    
    // MARK: - Removing Changed Objects
    
    func removeModels(for objectIds: Set<NSManagedObjectID>) {
        objectIds.forEach { objectId in
            users.removeValue(forKey: objectId)
        }
    }
}

private extension NSManagedObject {
    var canUseCached: Bool {
        !isUpdated
    }
}

extension NSManagedObjectContext {
    var databaseModelCache: DatabaseModelCache {
        if let cache = userInfo["DatabaseModelCache"] as? DatabaseModelCache {
            return cache
        }
        let cache = DatabaseModelCache()
        userInfo["DatabaseModelCache"] = cache
        return cache
    }
}
