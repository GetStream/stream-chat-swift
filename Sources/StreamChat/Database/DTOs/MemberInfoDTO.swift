//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(MemberInfoDTO)
class MemberInfoDTO: NSManagedObject {
    @NSManaged var userId: String
    @NSManaged var channelRoleRaw: String?
    @NSManaged var notificationsMuted: Bool
    @NSManaged var extraData: Data?
    @NSManaged var channel: ChannelDTO?
}

extension MemberInfoDTO {
    static func fetchRequest(for cid: ChannelId, userId: UserId) -> NSFetchRequest<MemberInfoDTO> {
        let request = NSFetchRequest<MemberInfoDTO>(entityName: MemberInfoDTO.entityName)
        MemberInfoDTO.applyPrefetchingState(to: request)
        request.predicate = NSPredicate(format: "channel.cid == %@ && userId == %@", cid.rawValue, userId)
        return request
    }

    static func load(cid: ChannelId, userId: UserId, context: NSManagedObjectContext) -> MemberInfoDTO? {
        load(by: fetchRequest(for: cid, userId: userId), context: context).first
    }

    static func loadOrCreate(
        userId: UserId,
        cid: ChannelId,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> MemberInfoDTO {
        let request = fetchRequest(for: cid, userId: userId)
        if let existing = load(by: request, context: context).first {
            return existing
        }

        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.userId = userId
        new.channel = ChannelDTO.loadOrCreate(cid: cid, context: context, cache: cache)
        return new
    }

    func asModel() throws -> ChatMessage.MemberInfo {
        let decodedExtraData: [String: RawJSON]
        do {
            decodedExtraData = try JSONDecoder.stream.decodeRawJSON(from: extraData)
        } catch {
            log.error("Failed to decode member info extra data. Error: \(error)")
            decodedExtraData = [:]
        }

        return ChatMessage.MemberInfo(
            channelRole: channelRoleRaw.map { MemberRole(rawChannelValue: $0) },
            notificationsMuted: notificationsMuted,
            extraData: decodedExtraData
        )
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func saveMemberInfo(
        payload: MemberInfoPayload,
        userId: UserId,
        cid: ChannelId,
        cache: PreWarmedCache?
    ) -> MemberInfoDTO {
        let dto = MemberInfoDTO.loadOrCreate(userId: userId, cid: cid, context: self, cache: cache)
        dto.channelRoleRaw = payload.channelRole
        dto.notificationsMuted = payload.notificationsMuted
        do {
            dto.extraData = try JSONEncoder.default.encode(payload.custom ?? [:])
        } catch {
            log.error("Failed to encode member info extra data. Error: \(error)")
            dto.extraData = nil
        }
        return dto
    }
}

extension ChannelDTO {
    func clearTypingMemberInfo(userId: UserId) {
        guard let dto = typingMemberInfos.first(where: { $0.userId == userId }) else { return }
        typingMemberInfos.remove(dto)
        managedObjectContext?.delete(dto)
    }

    func clearAllTypingMemberInfo() {
        typingMemberInfos.forEach { managedObjectContext?.delete($0) }
        typingMemberInfos.removeAll()
    }

    func typingMemberInfo(for userId: UserId) -> ChatMessage.MemberInfo? {
        try? typingMemberInfos.first(where: { $0.userId == userId })?.asModel()
    }
}
