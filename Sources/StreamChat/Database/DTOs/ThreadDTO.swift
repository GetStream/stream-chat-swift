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

    static func loadOrCreate(
        parentMessageId: MessageId,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> ThreadDTO {
        if let cachedObject = cache?.model(for: parentMessageId, context: context, type: ThreadDTO.self) {
            return cachedObject
        }

        let request = fetchRequest(for: parentMessageId)
        if let existing = load(by: request, context: context).first {
            return existing
        }

        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.parentMessageId = parentMessageId
        return new
    }

    static func fetchRequest(for parentMessageId: MessageId) -> NSFetchRequest<ThreadDTO> {
        let request = NSFetchRequest<ThreadDTO>(entityName: ThreadDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ThreadDTO.updatedAt, ascending: false)]
        request.predicate = NSPredicate(format: "parentMessageId == %@", parentMessageId)
        return request
    }

    static func threadListFetchRequest() -> NSFetchRequest<ThreadDTO> {
        let request = NSFetchRequest<ThreadDTO>(entityName: ThreadDTO.entityName)

        // Fetch results controller requires at least one sorting descriptor.
        // For now, it is not possible to change the thread sorting.
        let sortDescriptors: [NSSortDescriptor] = [
            .init(keyPath: \ThreadDTO.updatedAt, ascending: false)
        ]

        request.sortDescriptors = sortDescriptors
        return request
    }

    /// Populate the DTO.
    func fill(
        parentMessage: MessageDTO,
        title: String?,
        replyCount: Int64,
        participantCount: Int64,
        createdAt: DBDate,
        lastMessageAt: DBDate?,
        updatedAt: DBDate?,
        latestReplies: Set<MessageDTO>,
        threadParticipants: Set<ThreadParticipantDTO>,
        read: Set<ThreadReadDTO>,
        createdBy: UserDTO,
        channel: ChannelDTO
    ) {
        self.parentMessage = parentMessage
        self.title = title
        self.replyCount = replyCount
        self.participantCount = participantCount
        self.createdAt = createdAt
        self.lastMessageAt = lastMessageAt
        self.updatedAt = updatedAt
        self.latestReplies = latestReplies
        self.threadParticipants = threadParticipants
        self.read = read
        self.createdBy = createdBy
        self.channel = channel
    }
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

extension NSManagedObjectContext {
    func saveThreadList(payload: ThreadListPayload) -> [ThreadDTO] {
        let cache = payload.getPayloadToModelIdMappings(context: self)
        return payload.threads.compactMapLoggingError { threadPayload in
            try saveThread(payload: threadPayload, cache: cache)
        }
    }

    func saveThread(
        payload: ThreadPayload,
        cache: PreWarmedCache?
    ) throws -> ThreadDTO {
        let threadDTO = ThreadDTO.loadOrCreate(
            parentMessageId: payload.parentMessageId,
            context: self,
            cache: cache
        )
        let channelDTO = try saveChannel(
            payload: payload.channel,
            query: nil,
            cache: cache
        )
        let parentMessageDTO = try saveMessage(
            payload: payload.parentMessage,
            channelDTO: channelDTO,
            syncOwnReactions: false,
            cache: cache
        )

        let latestRepliesDTO: [MessageDTO] = try payload.latestReplies.map { replyPayload in
            let replyDTO = try saveMessage(
                payload: replyPayload,
                channelDTO: channelDTO,
                syncOwnReactions: false,
                cache: nil
            )
            return replyDTO
        }

        let threadParticipantsDTO: [ThreadParticipantDTO] = try payload.threadParticipants.map { participantPayload in
            let participantDTO = try saveThreadParticipant(
                payload: participantPayload,
                threadId: payload.parentMessageId,
                cache: cache
            )
            return participantDTO
        }

        let readsDTO: [ThreadReadDTO] = try payload.read.map { readPayload in
            let readDTO = try saveThreadRead(
                payload: readPayload,
                parentMessageId: payload.parentMessageId,
                cache: cache
            )
            return readDTO
        }

        let createdByUserDTO = try saveUser(payload: payload.createdBy)

        threadDTO.fill(
            parentMessage: parentMessageDTO,
            title: payload.title,
            replyCount: Int64(payload.replyCount),
            participantCount: Int64(payload.participantCount),
            createdAt: payload.createdAt.bridgeDate,
            lastMessageAt: payload.lastMessageAt?.bridgeDate,
            updatedAt: payload.updatedAt?.bridgeDate,
            latestReplies: Set(latestRepliesDTO),
            threadParticipants: Set(threadParticipantsDTO),
            read: Set(readsDTO),
            createdBy: createdByUserDTO,
            channel: channelDTO
        )

        return threadDTO
    }

    func deleteAllThreads() throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: ThreadDTO.entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try persistentStoreCoordinator?.execute(deleteRequest, with: self)
    }
}
