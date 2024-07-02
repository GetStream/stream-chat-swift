//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ThreadReadDTO)
class ThreadReadDTO: NSManagedObject {
    @NSManaged var user: UserDTO
    @NSManaged var lastReadAt: DBDate?
    @NSManaged var unreadMessagesCount: Int64
    @NSManaged var thread: ThreadDTO

    override func willSave() {
        super.willSave()

        // When the read is updated, we need to propagate this change up to holding thread
        if hasPersistentChangedValues, !thread.hasChanges, !thread.isDeleted {
            // this will not change object, but mark it as dirty, triggering updates
            thread.parentMessageId = thread.parentMessageId
        }
    }

    static func load(userId: String, context: NSManagedObjectContext) -> [ThreadReadDTO] {
        load(by: fetchRequest(userId: userId), context: context)
    }

    static func load(parentMessageId: MessageId, userId: String, context: NSManagedObjectContext) -> ThreadReadDTO? {
        load(by: fetchRequest(for: parentMessageId, userId: userId), context: context).first
    }

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

    static func fetchRequest(userId: String) -> NSFetchRequest<ThreadReadDTO> {
        let request = NSFetchRequest<ThreadReadDTO>(entityName: ThreadReadDTO.entityName)
        request.predicate = NSPredicate(format: "user.id == %@", userId)
        return request
    }

    static func fetchRequest(for parentMessageId: MessageId, userId: String) -> NSFetchRequest<ThreadReadDTO> {
        let request = NSFetchRequest<ThreadReadDTO>(entityName: ThreadReadDTO.entityName)
        request.predicate = NSPredicate(format: "thread.parentMessageId == %@ && user.id == %@", parentMessageId, userId)
        return request
    }
}

extension ThreadReadDTO {
    func asModel() throws -> ThreadRead {
        try .init(
            user: user.asModel(),
            lastReadAt: lastReadAt?.bridgeDate,
            unreadMessagesCount: Int(unreadMessagesCount)
        )
    }
}

extension NSManagedObjectContext {
    func saveThreadRead(
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

    func loadThreadRead(parentMessageId: MessageId, userId: String) -> ThreadReadDTO? {
        ThreadReadDTO.load(parentMessageId: parentMessageId, userId: userId, context: self)
    }

    func loadThreadReads(for userId: UserId) -> [ThreadReadDTO] {
        ThreadReadDTO.load(userId: userId, context: self)
    }

    func markThreadAsRead(parentMessageId: MessageId, userId: UserId, at readAt: Date) {
        if let read = loadThreadRead(parentMessageId: parentMessageId, userId: userId) {
            read.lastReadAt = readAt.bridgeDate
            read.unreadMessagesCount = 0
        } else {
            makeEmptyRead(parentMessageId: parentMessageId, userId: userId, readAt: readAt)
        }
    }

    func markThreadAsUnread(
        for parentMessageId: MessageId,
        userId: UserId
    ) {
        let read = loadThreadRead(parentMessageId: parentMessageId, userId: userId)
            ?? makeEmptyRead(parentMessageId: parentMessageId, userId: userId, readAt: nil)

        // At the moment, the backend sets the value to 1
        // Although ideally it should be equal to the replyCount?
        read?.unreadMessagesCount = 1
        read?.lastReadAt = nil
    }

    func incrementThreadUnreadCount(parentMessageId: MessageId, for userId: String) -> ThreadReadDTO? {
        let read = loadThreadRead(parentMessageId: parentMessageId, userId: userId)
            ?? makeEmptyRead(parentMessageId: parentMessageId, userId: userId, readAt: Date())
        read?.unreadMessagesCount += 1
        return read
    }

    @discardableResult
    private func makeEmptyRead(parentMessageId: MessageId, userId: UserId, readAt: Date?) -> ThreadReadDTO? {
        guard let thread = thread(parentMessageId: parentMessageId, cache: nil),
              let user = user(id: userId) else {
            return nil
        }

        let read = ThreadReadDTO.loadOrCreate(
            parentMessageId: parentMessageId,
            userId: userId,
            context: self,
            cache: nil
        )
        read.thread = thread
        read.user = user
        read.lastReadAt = readAt?.bridgeDate
        read.unreadMessagesCount = 0
        return read
    }
}
