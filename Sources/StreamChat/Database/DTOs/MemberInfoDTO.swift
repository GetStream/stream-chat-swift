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
    func update(from member: MemberInfoPayload) {
        channelRoleRaw = member.channelRole
        notificationsMuted = member.notificationsMuted
        do {
            extraData = try JSONEncoder.default.encode(member.custom ?? [:])
        } catch {
            log.error("Failed to encode member info extra data. Error: \(error)")
            extraData = nil
        }
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

extension ChannelDTO {
    func updateTypingMemberInfo(userId: UserId, from member: MemberInfoPayload) {
        let dto: MemberInfoDTO
        if let existing = typingMemberInfos.first(where: { $0.userId == userId }) {
            dto = existing
        } else {
            guard let managedObjectContext else { return }
            dto = MemberInfoDTO(context: managedObjectContext)
            dto.userId = userId
            dto.channel = self
        }
        dto.update(from: member)
    }

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
