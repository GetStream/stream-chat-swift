//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

final class DatabaseModelCache {
    private var channelMembers = [NSManagedObjectID: ChatChannelMember]()
    private var channelReads = [NSManagedObjectID: CachedChannelRead]()
    private var users = [NSManagedObjectID: ChatUser]()
    
    // MARK: - Channel Members
    
    func channelMember(for objectId: NSManagedObjectID, context: NSManagedObjectContext) -> ChatChannelMember? {
        cachedData(for: objectId, in: channelMembers, tag: "members", context: context)
    }
    
    func setChannelMember(_ member: ChatChannelMember, forObjectId objectId: NSManagedObjectID) {
        channelMembers[objectId] = member
    }
    
    // MARK: - Channel Reads
    
    func channelRead(for objectId: NSManagedObjectID, context: NSManagedObjectContext) -> CachedChannelRead? {
        cachedData(for: objectId, in: channelReads, tag: "reads", context: context)
    }
    
    func setChannelRead(_ model: ChatChannelRead, for dto: ChannelReadDTO) {
        channelReads[dto.objectID] = CachedChannelRead(
            model: model,
            userObjectId: dto.user.objectID
        )
    }
    
    // MARK: - Users
    
    func user(for objectId: NSManagedObjectID, context: NSManagedObjectContext) -> ChatUser? {
        cachedData(for: objectId, in: users, tag: "users", context: context)
    }
    
    func setUser(_ user: ChatUser, forObjectId objectId: NSManagedObjectID) {
        users[objectId] = user
    }
    
    // MARK: - Accessing Cached Data
    
    private var cacheHits = [String: Int]()
    private var cacheMisses = [String: Int]()
    
    private func registerCacheHit(for identifier: String) {
        let count = cacheHits[identifier] ?? 0
        cacheHits[identifier] = count + 1
    }
    
    private func registerCacheMiss(for identifier: String) {
        let count = cacheMisses[identifier] ?? 0
        cacheMisses[identifier] = count + 1
    }
    
    func printStatistics(identifier: String) {
        let keys = Set(cacheHits.keys.compactMap { $0 }).union(cacheMisses.keys.compactMap { $0 })
        for key in keys.sorted() {
            print(
                identifier.padding(toLength: 10, withPad: " ", startingAt: 0),
                key.padding(toLength: 8, withPad: " ", startingAt: 0),
                "hits",
                cacheHits[key] ?? 0,
                "misses",
                cacheMisses[key] ?? 0
            )
        }
    }
    
    private func cachedData<CachedData>(
        for objectId: NSManagedObjectID,
        in storage: [NSManagedObjectID: CachedData],
        tag: String,
        context: NSManagedObjectContext
    ) -> CachedData? {
        if !context.hasChanges, let cachedData = storage[objectId] {
            #if DEBUG
            registerCacheHit(for: tag)
            #endif
            return cachedData
        } else {
            #if DEBUG
            registerCacheMiss(for: tag)
            #endif
            return nil
        }
    }
    
    // MARK: - Removing Changed Objects
    
    func removeModels(for objectIds: Set<NSManagedObjectID>) {
        objectIds.forEach { objectId in
            channelMembers.removeValue(forKey: objectId)
            channelReads.removeValue(forKey: objectId)
            users.removeValue(forKey: objectId)
        }
    }
}

extension DatabaseModelCache {
    struct CachedChannelRead {
        let model: ChatChannelRead
        let userObjectId: NSManagedObjectID
    }
}

extension NSManagedObject {
    var databaseModelCacheAndContext: (cache: DatabaseModelCache, context: NSManagedObjectContext)? {
        guard let context = managedObjectContext else { return nil }
        return (context.databaseModelCache, context)
    }
    
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
