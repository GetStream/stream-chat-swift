//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
    @NSManaged var activeParticipantCount: Int64
    @NSManaged var createdAt: DBDate
    @NSManaged var lastMessageAt: DBDate?
    @NSManaged var updatedAt: DBDate?
    @NSManaged var latestReplies: Set<MessageDTO>
    @NSManaged var threadParticipants: Set<ThreadParticipantDTO>
    @NSManaged var read: Set<ThreadReadDTO>
    @NSManaged var createdBy: UserDTO
    @NSManaged var channel: ChannelDTO
    @NSManaged var extraData: Data

    // Only update this value when fetching thread lists, to avoid live updates
    @NSManaged var currentUserUnreadCount: Int64

    static func loadOrCreate(
        parentMessageId: MessageId,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> ThreadDTO {
        if let existing = load(
            parentMessageId: parentMessageId,
            context: context,
            cache: cache
        ) {
            return existing
        }

        let request = fetchRequest(for: parentMessageId)
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.parentMessageId = parentMessageId
        return new
    }

    static func load(
        parentMessageId: MessageId,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> ThreadDTO? {
        if let cachedObject = cache?.model(for: parentMessageId, context: context, type: ThreadDTO.self) {
            return cachedObject
        }

        let request = fetchRequest(for: parentMessageId)
        return load(by: request, context: context).first
    }

    static func fetchRequest(for parentMessageId: MessageId) -> NSFetchRequest<ThreadDTO> {
        let request = NSFetchRequest<ThreadDTO>(entityName: ThreadDTO.entityName)
        ThreadDTO.applyPrefetchingState(to: request)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ThreadDTO.updatedAt, ascending: false)]
        request.predicate = NSPredicate(format: "parentMessageId == %@", parentMessageId)
        return request
    }

    static func threadListFetchRequest(query: ThreadListQuery) -> NSFetchRequest<ThreadDTO> {
        let request = NSFetchRequest<ThreadDTO>(entityName: ThreadDTO.entityName)
        ThreadDTO.applyPrefetchingState(to: request)

        let defaultSortDescriptors: [NSSortDescriptor] = [
            .init(keyPath: \ThreadDTO.currentUserUnreadCount, ascending: false),
            .init(keyPath: \ThreadDTO.lastMessageAt, ascending: false),
            .init(keyPath: \ThreadDTO.parentMessageId, ascending: false)
        ]
        var sortDescriptors: [NSSortDescriptor] = defaultSortDescriptors
        if !query.sort.isEmpty {
            sortDescriptors = query.sort.compactMap {
                $0.key.sortDescriptor(isAscending: $0.isAscending)
            }
        }
        request.sortDescriptors = sortDescriptors

        // For now, we don't have a `ThreadListQueryDTO` like the `ChannelListQueryDTO`.
        // The automatic predicate should be enough for threads. If needed, we can always create it later.
        if let predicate = query.filter?.predicate {
            request.predicate = predicate
        }
        request.fetchLimit = query.limit
        request.fetchBatchSize = query.limit

        return request
    }

    /// Populate the DTO.
}

extension ThreadDTO {
    override class func prefetchedRelationshipKeyPaths() -> [String] {
        [
            KeyPath.string(\ThreadDTO.channel),
            KeyPath.string(\ThreadDTO.createdBy),
            KeyPath.string(\ThreadDTO.latestReplies),
            KeyPath.string(\ThreadDTO.parentMessage),
            KeyPath.string(\ThreadDTO.read),
            KeyPath.string(\ThreadDTO.threadParticipants)
        ]
    }
}

extension ThreadDTO {
    func asModel() throws -> ChatThread {
        try isNotDeleted()
        
        let extraData: [String: RawJSON]
        do {
            extraData = try JSONDecoder.stream.decodeRawJSON(from: self.extraData)
        } catch {
            log.error(
                "Failed to decode extra data for thread with id: <\(parentMessageId)>, using default value instead. Error: \(error)"
            )
            extraData = [:]
        }

        return try .init(
            parentMessageId: parentMessageId,
            parentMessage: parentMessage.asModel(),
            channel: channel.asModel(),
            createdBy: createdBy.asModel(),
            replyCount: Int(replyCount),
            participantCount: Int(participantCount),
            activeParticipantCount: Int(activeParticipantCount),
            threadParticipants: threadParticipants.map { try $0.asModel() },
            lastMessageAt: lastMessageAt?.bridgeDate,
            createdAt: createdAt.bridgeDate,
            updatedAt: updatedAt?.bridgeDate,
            title: title,
            latestReplies: latestReplies
                .sorted(by: { $0.createdAt.bridgeDate < $1.createdAt.bridgeDate })
                .map { try $0.asModel() },
            reads: read.map { try $0.asModel() },
            extraData: extraData
        )
    }
}

extension NSManagedObjectContext {
    func thread(
        parentMessageId: MessageId,
        cache: PreWarmedCache?
    ) -> ThreadDTO? {
        ThreadDTO.load(
            parentMessageId: parentMessageId,
            context: self,
            cache: cache
        )
    }

    func saveThreadList(payload: QueryThreadsResponse) -> [ThreadDTO] {
        let cache = payload.getPayloadToModelIdMappings(context: self)
        return payload.threads.compactMapLoggingError { threadPayload in
            try saveThread(payload: threadPayload, cache: cache)
        }
    }

    func saveThread(
        payload: ThreadStateResponse,
        cache: PreWarmedCache?
    ) throws -> ThreadDTO {
        guard let channel = payload.channel else {
            throw ClientError("Thread payload is missing a channel")
        }
        guard let parentMessage = payload.parentMessage else {
            throw ClientError("Thread payload is missing a parent message")
        }
        guard let createdBy = payload.createdBy else {
            throw ClientError("Thread payload is missing a creator")
        }
        let threadDTO = ThreadDTO.loadOrCreate(
            parentMessageId: payload.parentMessageId,
            context: self,
            cache: cache
        )
        let channelDTO = try saveChannel(
            payload: channel,
            query: nil,
            cache: cache
        )
        let parentMessageDTO = try saveMessage(
            payload: parentMessage,
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

        let threadParticipants = payload.threadParticipants ?? []
        let threadParticipantsDTO: [ThreadParticipantDTO] = try threadParticipants.map { participantPayload in
            let participantDTO = try saveThreadParticipant(
                payload: participantPayload,
                threadId: payload.parentMessageId,
                cache: cache
            )
            return participantDTO
        }

        let readsDTO: [ThreadReadDTO] = try (payload.read ?? []).map { readPayload in
            let readDTO = try saveThreadRead(
                payload: readPayload,
                parentMessageId: payload.parentMessageId,
                cache: cache
            )
            return readDTO
        }

        let createdByUserDTO = try saveUser(payload: createdBy)

        let extraData: Data
        do {
            extraData = try JSONEncoder.default.encode(payload.custom)
        } catch {
            extraData = Data()
        }

        var currentUserUnreadCount = 0
        if let currentUserId = currentUser?.user.id {
            let currentUserRead = payload.read?.first(where: { $0.user.id == currentUserId })
            currentUserUnreadCount = currentUserRead?.unreadMessages ?? 0
        }

        if let draft = payload.draft {
            parentMessageDTO.draftReply = try saveDraftMessage(payload: draft, for: channel.cid, cache: cache)
        } else {
            /// If the payload does not contain a draft reply, we should
            /// delete the existing draft reply if it exists.
            if let draft = parentMessageDTO.draftReply {
                deleteDraftMessage(in: channel.cid, threadId: draft.parentMessageId)
                parentMessageDTO.draftReply = nil
            }
        }

        saveThreadCommonFields(
            activeParticipantCount: payload.activeParticipantCount ?? 0,
            createdAt: payload.createdAt,
            dto: threadDTO,
            lastMessageAt: payload.lastMessageAt,
            participantCount: payload.participantCount,
            replyCount: payload.replyCount,
            title: payload.title,
            updatedAt: payload.updatedAt
        )
        threadDTO.channel = channelDTO
        threadDTO.createdBy = createdByUserDTO
        threadDTO.currentUserUnreadCount = Int64(currentUserUnreadCount)
        threadDTO.extraData = extraData
        threadDTO.latestReplies = Set(latestRepliesDTO)
        threadDTO.parentMessage = parentMessageDTO
        threadDTO.read = Set(readsDTO)
        threadDTO.threadParticipants = Set(threadParticipantsDTO)

        return threadDTO
    }

    @discardableResult
    func saveThread(partialPayload: ThreadResponse) throws -> ThreadDTO? {
        // Read events deliver a thread without its parent message and creator,
        // therefore only the already stored thread can be updated.
        guard let channel = partialPayload.channel,
              let parentMessage = partialPayload.parentMessage,
              let createdBy = partialPayload.createdBy else {
            guard let threadDTO = ThreadDTO.load(
                parentMessageId: partialPayload.parentMessageId,
                context: self,
                cache: nil
            ) else {
                return nil
            }
            saveThreadCommonFields(
                activeParticipantCount: partialPayload.activeParticipantCount,
                createdAt: partialPayload.createdAt,
                dto: threadDTO,
                lastMessageAt: partialPayload.lastMessageAt,
                participantCount: partialPayload.participantCount,
                replyCount: partialPayload.replyCount,
                title: partialPayload.title,
                updatedAt: partialPayload.updatedAt
            )
            return threadDTO
        }
        let threadDTO = ThreadDTO.loadOrCreate(
            parentMessageId: partialPayload.parentMessageId,
            context: self,
            cache: nil
        )
        let channelDTO = try saveChannel(
            payload: channel,
            query: nil,
            cache: nil
        )
        let parentMessageDTO = try saveMessage(
            payload: parentMessage,
            channelDTO: channelDTO,
            syncOwnReactions: false,
            cache: nil
        )

        let createdByUserDTO = try saveUser(payload: createdBy)

        let extraData: Data
        do {
            extraData = try JSONEncoder.default.encode(partialPayload.custom)
        } catch {
            extraData = Data()
        }

        saveThreadCommonFields(
            activeParticipantCount: partialPayload.activeParticipantCount,
            createdAt: partialPayload.createdAt,
            dto: threadDTO,
            lastMessageAt: partialPayload.lastMessageAt,
            participantCount: partialPayload.participantCount,
            replyCount: partialPayload.replyCount,
            title: partialPayload.title,
            updatedAt: partialPayload.updatedAt
        )
        threadDTO.channel = channelDTO
        threadDTO.createdBy = createdByUserDTO
        threadDTO.extraData = extraData
        threadDTO.parentMessage = parentMessageDTO

        return threadDTO
    }

    private func saveThreadCommonFields(
        activeParticipantCount: Int?,
        createdAt: Date,
        dto: ThreadDTO,
        lastMessageAt: Date?,
        participantCount: Int,
        replyCount: Int,
        title: String,
        updatedAt: Date
    ) {
        dto.createdAt = createdAt.bridgeDate
        dto.lastMessageAt = lastMessageAt?.bridgeDate
        dto.participantCount = Int64(participantCount)
        dto.replyCount = Int64(replyCount)
        dto.title = title
        dto.updatedAt = updatedAt.bridgeDate
        if let activeParticipantCount {
            dto.activeParticipantCount = Int64(activeParticipantCount)
        }
    }

    func deleteAllThreads() throws {
        let fetchRequest: NSFetchRequest<ThreadDTO> = NSFetchRequest(entityName: ThreadDTO.entityName)
        let results = try fetch(fetchRequest)
        results.forEach { delete($0) }
    }

    func delete(thread: ThreadDTO) {
        delete(thread)
    }
}

extension ThreadDTO {
    var reuseId: String {
        channel.cid + parentMessageId
    }
}

extension ChatThread {
    var reuseId: String {
        channel.cid.rawValue + parentMessageId
    }
}
