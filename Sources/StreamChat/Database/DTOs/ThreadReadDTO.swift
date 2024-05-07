//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ThreadReadDTO)
package class ThreadReadDTO: NSManagedObject {
    @NSManaged var user: UserDTO
    @NSManaged var lastReadAt: DBDate?
    @NSManaged var unreadMessagesCount: Int64
    @NSManaged var thread: ThreadDTO

    static func loadOrCreate(
        parentMessageId: MessageId,
        userId: String,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> ThreadReadDTO {
        let request = fetchRequest(for: parentMessageId, userId: userId)
        if let existing = load(by: request, context: context).first {
            return existing
        }

        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.thread = ThreadDTO.loadOrCreate(parentMessageId: parentMessageId, context: context, cache: cache)
        new.user = UserDTO.loadOrCreate(id: userId, context: context, cache: cache)
        return new
    }

    static func fetchRequest(for parentMessageId: MessageId, userId: String) -> NSFetchRequest<ThreadReadDTO> {
        let request = NSFetchRequest<ThreadReadDTO>(entityName: ThreadReadDTO.entityName)
        request.predicate = NSPredicate(format: "thread.parentMessageId == %@ && user.id == %@", parentMessageId, userId)
        return request
    }
}

extension ThreadReadDTO {
    package func asModel() throws -> ThreadRead {
        try .init(
            user: user.asModel(),
            lastReadAt: lastReadAt?.bridgeDate,
            unreadMessagesCount: Int(unreadMessagesCount)
        )
    }
}

extension NSManagedObjectContext {
    package func saveThreadRead(
        payload: ThreadReadPayload,
        parentMessageId: String,
        cache: PreWarmedCache?
    ) throws -> ThreadReadDTO {
        let dto = ThreadReadDTO.loadOrCreate(
            parentMessageId: parentMessageId,
            userId: payload.user.id,
            context: self,
            cache: cache
        )
        dto.user = try saveUser(payload: payload.user)
        dto.lastReadAt = payload.lastReadAt?.bridgeDate
        dto.unreadMessagesCount = Int64(payload.unreadMessagesCount)
        return dto
    }
}
