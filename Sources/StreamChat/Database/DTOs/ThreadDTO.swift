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
