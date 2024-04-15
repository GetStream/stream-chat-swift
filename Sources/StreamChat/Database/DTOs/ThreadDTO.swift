//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ThreadDTO)
class ThreadDTO: NSManagedObject {
    @NSManaged var parentMessageId: String
    @NSManaged var parentMessage: MessageDTO
    @NSManaged var title: String?
    @NSManaged var replyCount: Int64
    @NSManaged var participantCount: Int64
    @NSManaged var createdAt: DBDate
    @NSManaged var lastMessageAt: DBDate?
    @NSManaged var updatedAt: DBDate?
    @NSManaged var latestReplies: Set<MessageDTO>
    @NSManaged var threadParticipants: Set<ThreadParticipantDTO>
    @NSManaged var read: Set<ThreadReadDTO>
    @NSManaged var createdBy: UserDTO
    @NSManaged var channel: ChannelDTO
}

extension ThreadDTO {
    func asModel() throws -> ChatThread {
        try .init(
            parentMessageId: parentMessageId,
            parentMessage: parentMessage.asModel(),
            channel: channel.asModel(),
            createdBy: createdBy.asModel(),
            replyCount: Int(replyCount),
            participantCount: Int(participantCount),
            threadParticipants: threadParticipants.map { try $0.asModel() },
            lastMessageAt: lastMessageAt?.bridgeDate,
            createdAt: createdAt.bridgeDate,
            updatedAt: updatedAt?.bridgeDate,
            title: title,
            latestReplies: latestReplies.map { try $0.asModel() },
            reads: read.map { try $0.asModel() }
        )
    }
}
