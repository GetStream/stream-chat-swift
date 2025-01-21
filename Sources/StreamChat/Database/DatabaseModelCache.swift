//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

final class DatabaseModelCache {
    private var channelReads = [NSManagedObjectID: ChatChannelRead]()
    private var channelReadsUserIds = [NSManagedObjectID: NSManagedObjectID]()
    private var users = [NSManagedObjectID: ChatUser]()
    private(set) var cacheMisses = 0
    private(set) var cacheHits = 0
    
    // MARK: - Channel Reads
    
    func channelRead(for objectID: NSManagedObjectID, updated: Bool) -> (read: ChatChannelRead, userObjectID: NSManagedObjectID)? {
        guard let channelRead = model(for: objectID, updated: updated, in: channelReads) else { return nil }
        guard let channelReadUserId = channelReadsUserIds[objectID] else { return nil }
        return (read: channelRead, userObjectID: channelReadUserId)
    }
    
    func setChannelRead(_ read: ChatChannelRead, for dto: ChannelReadDTO) {
        channelReads[dto.objectID] = read
        channelReadsUserIds[dto.objectID] = dto.user.objectID
    }
    
    // MARK: - Users
    
    func user(for objectID: NSManagedObjectID, updated: Bool) -> ChatUser? {
        model(for: objectID, updated: updated, in: users)
    }
    
    func setUser(_ user: ChatUser, forObjectID objectId: NSManagedObjectID) {
        users[objectId] = user
    }
    
    // MARK: - Accessing the Storage
    
    private func model<Model>(for objectID: NSManagedObjectID, updated: Bool, in storage: [NSManagedObjectID: Model]) -> Model? {
        if updated {
            cacheMisses += 1
            return nil
        }
        if let model = storage[objectID] {
            cacheHits += 1
            return model
        }
        cacheMisses += 1
        return nil
    }
    
    // MARK: - Removing Changed Objects
    
    func removeModels(for objectIds: Set<NSManagedObjectID>) {
        objectIds.forEach { objectId in
            channelReads.removeValue(forKey: objectId)
            channelReadsUserIds.removeValue(forKey: objectId)
            users.removeValue(forKey: objectId)
        }
    }
}

private extension NSManagedObject {
    var canUseCached: Bool {
        !isUpdated
    }
}

extension NSManagedObject {
    var databaseModelCache: DatabaseModelCache? {
        managedObjectContext?.databaseModelCache
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
