//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ThreadParticipantDTO)
class ThreadParticipantDTO: NSManagedObject {
    @NSManaged var createdAt: DBDate
    @NSManaged var lastReadAt: DBDate?
    @NSManaged var threadId: String
    @NSManaged var user: UserDTO
    @NSManaged var thread: ThreadDTO

    static func fetchRequest(for threadId: String, userId: String) -> NSFetchRequest<ThreadParticipantDTO> {
        let request = NSFetchRequest<ThreadParticipantDTO>(entityName: ThreadParticipantDTO.entityName)
        request.predicate = NSPredicate(format: "threadId == %@ && user.id == %@", threadId, userId)
        return request
    }

    static func loadOrCreate(
        threadId: String,
        userId: String,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> ThreadParticipantDTO {
        let request = fetchRequest(for: threadId, userId: userId)
        if let existing = load(by: request, context: context).first {
            return existing
        }

        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.thread = ThreadDTO.loadOrCreate(parentMessageId: threadId, context: context, cache: cache)
        new.user = UserDTO.loadOrCreate(id: userId, context: context, cache: cache)
        return new
    }
}

extension ThreadParticipantDTO {
    func asModel() throws -> ThreadParticipant {
        guard !isDeleted else { throw ClientError.DeletedModel(modelType: Self.self) }
        return try .init(
            user: user.asModel(),
            threadId: threadId,
            createdAt: createdAt.bridgeDate,
            lastReadAt: lastReadAt?.bridgeDate
        )
    }
}

extension NSManagedObjectContext {
    func saveThreadParticipant(
        payload: ThreadParticipantPayload,
        threadId: String,
        cache: PreWarmedCache?
    ) throws -> ThreadParticipantDTO {
        let dto = ThreadParticipantDTO.loadOrCreate(
            threadId: threadId,
            userId: payload.user.id,
            context: self,
            cache: cache
        )
        dto.user = try saveUser(payload: payload.user)
        dto.lastReadAt = payload.lastReadAt?.bridgeDate
        dto.createdAt = payload.createdAt.bridgeDate
        dto.threadId = threadId
        return dto
    }
}
