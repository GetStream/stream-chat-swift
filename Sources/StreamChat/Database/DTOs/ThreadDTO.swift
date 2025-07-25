//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
    func fill(
        parentMessage: MessageDTO,
        title: String?,
        replyCount: Int64,
        participantCount: Int64,
        activeParticipantCount: Int64?,
        createdAt: DBDate,
        lastMessageAt: DBDate?,
        updatedAt: DBDate?,
        latestReplies: Set<MessageDTO>?,
        threadParticipants: Set<ThreadParticipantDTO>?,
        read: Set<ThreadReadDTO>?,
        createdBy: UserDTO,
        channel: ChannelDTO,
        currentUserUnreadCount: Int?,
        extraData: Data
    ) {
        self.parentMessage = parentMessage
        self.title = title
        self.replyCount = replyCount
        self.participantCount = participantCount
        if let activeParticipantCount {
            self.activeParticipantCount = activeParticipantCount
        }
        self.createdAt = createdAt
        self.lastMessageAt = lastMessageAt
        self.updatedAt = updatedAt
        self.createdBy = createdBy
        self.channel = channel
        self.extraData = extraData

        /// For partial thread response, the properties below won't be returned.
        /// We need to make sure we don't reset this values from the current state.
        if let latestReplies {
            self.latestReplies = latestReplies
        }
        if let threadParticipants {
            self.threadParticipants = threadParticipants
        }
        if let read {
            self.read = read
        }

        // currentUserUnreadCount should only be updated when fetching thread list,
        // not in events or when marking the thread read to avoid thread list live updates.
        if let currentUserUnreadCount {
            self.currentUserUnreadCount = Int64(currentUserUnreadCount)
        }
    }
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

        let extraData: Data
        do {
            extraData = try JSONEncoder.default.encode(payload.extraData)
        } catch {
            extraData = Data()
        }

        var currentUserUnreadCount = 0
        if let currentUserId = currentUser?.user.id {
            let currentUserRead = payload.read.first(where: { $0.user.id == currentUserId })
            currentUserUnreadCount = currentUserRead?.unreadMessagesCount ?? 0
        }

        if let draft = payload.draft {
            parentMessageDTO.draftReply = try saveDraftMessage(payload: draft, for: payload.channel.cid, cache: cache)
        } else {
            /// If the payload does not contain a draft reply, we should
            /// delete the existing draft reply if it exists.
            if let draft = parentMessageDTO.draftReply {
                deleteDraftMessage(in: payload.channel.cid, threadId: draft.parentMessageId)
                parentMessageDTO.draftReply = nil
            }
        }

        threadDTO.fill(
            parentMessage: parentMessageDTO,
            title: payload.title,
            replyCount: Int64(payload.replyCount),
            participantCount: Int64(payload.participantCount),
            activeParticipantCount: Int64(payload.activeParticipantCount),
            createdAt: payload.createdAt.bridgeDate,
            lastMessageAt: payload.lastMessageAt?.bridgeDate,
            updatedAt: payload.updatedAt?.bridgeDate,
            latestReplies: Set(latestRepliesDTO),
            threadParticipants: Set(threadParticipantsDTO),
            read: Set(readsDTO),
            createdBy: createdByUserDTO,
            channel: channelDTO,
            currentUserUnreadCount: currentUserUnreadCount,
            extraData: extraData
        )

        return threadDTO
    }

    @discardableResult
    func saveThread(partialPayload: ThreadPartialPayload) throws -> ThreadDTO {
        let threadDTO = ThreadDTO.loadOrCreate(
            parentMessageId: partialPayload.parentMessageId,
            context: self,
            cache: nil
        )
        let channelDTO = try saveChannel(
            payload: partialPayload.channel,
            query: nil,
            cache: nil
        )
        let parentMessageDTO = try saveMessage(
            payload: partialPayload.parentMessage,
            channelDTO: channelDTO,
            syncOwnReactions: false,
            cache: nil
        )

        let createdByUserDTO = try saveUser(payload: partialPayload.createdBy)

        let extraData: Data
        do {
            extraData = try JSONEncoder.default.encode(partialPayload.extraData)
        } catch {
            extraData = Data()
        }

        threadDTO.fill(
            parentMessage: parentMessageDTO,
            title: partialPayload.title,
            replyCount: Int64(partialPayload.replyCount),
            participantCount: Int64(partialPayload.participantCount),
            activeParticipantCount: partialPayload.activeParticipantCount.map(Int64.init),
            createdAt: partialPayload.createdAt.bridgeDate,
            lastMessageAt: partialPayload.lastMessageAt?.bridgeDate,
            updatedAt: partialPayload.updatedAt?.bridgeDate,
            latestReplies: nil,
            threadParticipants: nil,
            read: nil,
            createdBy: createdByUserDTO,
            channel: channelDTO,
            currentUserUnreadCount: nil,
            extraData: extraData
        )

        return threadDTO
    }

    @discardableResult
    func saveThread(detailsPayload: ThreadDetailsPayload) throws -> ThreadDTO {
        let threadDTO = ThreadDTO.loadOrCreate(
            parentMessageId: detailsPayload.parentMessageId,
            context: self,
            cache: nil
        )
        
        threadDTO.replyCount = Int64(detailsPayload.replyCount)
        threadDTO.participantCount = Int64(detailsPayload.participantCount)
        if let activeParticipantCount = detailsPayload.activeParticipantCount {
            threadDTO.activeParticipantCount = Int64(activeParticipantCount)
        }
        threadDTO.lastMessageAt = detailsPayload.lastMessageAt?.bridgeDate
        threadDTO.updatedAt = detailsPayload.updatedAt.bridgeDate
        threadDTO.title = detailsPayload.title

        return threadDTO
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
