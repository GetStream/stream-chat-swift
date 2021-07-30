//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ChannelMuteDTO)
final class ChannelMuteDTO: NSManagedObject {
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var channel: ChannelDTO
    @NSManaged var user: UserDTO

    static func fetchRequest(userId: String) -> NSFetchRequest<ChannelMuteDTO> {
        let request = NSFetchRequest<ChannelMuteDTO>(entityName: ChannelMuteDTO.entityName)
        request.predicate = NSPredicate(format: "user.id == %@", userId)
        return request
    }

    static func fetchRequest(for cid: ChannelId) -> NSFetchRequest<ChannelMuteDTO> {
        let request = NSFetchRequest<ChannelMuteDTO>(entityName: ChannelMuteDTO.entityName)
        request.predicate = NSPredicate(format: "channel.cid == %@", cid.rawValue)
        return request
    }

    static func fetchRequest(for cid: ChannelId, userId: String) -> NSFetchRequest<ChannelMuteDTO> {
        let request = NSFetchRequest<ChannelMuteDTO>(entityName: ChannelMuteDTO.entityName)
        request.predicate = NSPredicate(format: "channel.cid == %@ && user.id == %@", cid.rawValue, userId)
        return request
    }

    static func load(userId: String, context: NSManagedObjectContext) -> [ChannelMuteDTO] {
        let request = fetchRequest(userId: userId)
        return try! context.fetch(request)
    }

    static func load(cid: ChannelId, context: NSManagedObjectContext) -> [ChannelMuteDTO] {
        let request = fetchRequest(for: cid)
        return try! context.fetch(request)
    }

    static func load(cid: ChannelId, userId: String, context: NSManagedObjectContext) -> ChannelMuteDTO? {
        let request = fetchRequest(for: cid, userId: userId)
        return try! context.fetch(request).first
    }

    static func loadOrCreate(cid: ChannelId, userId: String, context: NSManagedObjectContext) -> ChannelMuteDTO {
        if let existing = Self.load(cid: cid, userId: userId, context: context) {
            return existing
        }

        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! ChannelMuteDTO
        new.channel = ChannelDTO.loadOrCreate(cid: cid, context: context)
        new.user = UserDTO.loadOrCreate(id: userId, context: context)
        return new
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func saveChannelMute(payload: MutedChannelPayload) throws -> ChannelMuteDTO {
        let dto = ChannelMuteDTO.loadOrCreate(cid: payload.mutedChannel.cid, userId: payload.user.id, context: self)

        dto.user = try saveUser(payload: payload.user)
        dto.channel = try saveChannel(payload: payload.mutedChannel, query: nil)
        dto.createdAt = payload.createdAt
        dto.updatedAt = payload.updatedAt

        return dto
    }

    func loadChannelMute(cid: ChannelId, userId: String) -> ChannelMuteDTO? {
        ChannelMuteDTO.load(cid: cid, userId: userId, context: self)
    }

    func loadChannelMutes(for userId: UserId) -> [ChannelMuteDTO] {
        ChannelMuteDTO.load(userId: userId, context: self)
    }

    func loadChannelMutes(for cid: ChannelId) -> [ChannelMuteDTO] {
        ChannelMuteDTO.load(cid: cid, context: self)
    }
}
