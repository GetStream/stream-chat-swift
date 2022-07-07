//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(MessageDTO)
class MessageDTO: NSManagedObject {
    @NSManaged fileprivate var localMessageStateRaw: String?
    
    @NSManaged var id: String
    @NSManaged var text: String
    @NSManaged var type: String
    @NSManaged var command: String?
    @NSManaged var createdAt: DBDate
    @NSManaged var updatedAt: DBDate
    @NSManaged var deletedAt: DBDate?
    @NSManaged var isHardDeleted: Bool
    @NSManaged var args: String?
    @NSManaged var parentMessageId: MessageId?
    @NSManaged var showReplyInChannel: Bool
    @NSManaged var replyCount: Int32
    @NSManaged var extraData: Data?
    @NSManaged var isSilent: Bool
    @NSManaged var isShadowed: Bool
    @NSManaged var reactionScores: [String: Int]
    @NSManaged var reactionCounts: [String: Int]

    @NSManaged var latestReactions: [String]
    @NSManaged var ownReactions: [String]
    
    @NSManaged var translations: [String: String]?

    @NSManaged var user: UserDTO
    @NSManaged var mentionedUsers: Set<UserDTO>
    @NSManaged var threadParticipants: NSOrderedSet
    @NSManaged var channel: ChannelDTO?
    @NSManaged var replies: Set<MessageDTO>
    @NSManaged var flaggedBy: CurrentUserDTO?
    @NSManaged var attachments: Set<AttachmentDTO>
    @NSManaged var quotedMessage: MessageDTO?
    @NSManaged var quotedBy: Set<MessageDTO>
    @NSManaged var searches: Set<MessageSearchQueryDTO>
    @NSManaged var previewOfChannel: ChannelDTO?

    /// If the message is sent by the current user, this field
    /// contains channel reads of other channel members (excluding the current user),
    /// where `read.lastRead >= self.createdAt`.
    ///
    /// If the message has a channel read of a member, it is considered as seen/read by
    /// that member.
    ///
    /// For messages authored NOT by the current user this field is always empty.
    @NSManaged var reads: Set<ChannelReadDTO>
    
    @NSManaged var pinned: Bool
    @NSManaged var pinnedBy: UserDTO?
    @NSManaged var pinnedAt: DBDate?
    @NSManaged var pinExpires: DBDate?

    // The timestamp the message was created locally. Applies only for the messages of the current user.
    @NSManaged var locallyCreatedAt: DBDate?
    
    // We use `Date!` to replicate a required value. The value must be marked as optional in the CoreData model, because we change
    // it in the `willSave` phase, which happens after the validation.
    @NSManaged var defaultSortingKey: DBDate!
    
    override func willSave() {
        super.willSave()

        guard !isDeleted else {
            return
        }
        
        // Manually mark the channel as dirty to trigger the entity update and give the UI a chance
        // to reload the channel cell to reflect the updated preview.
        if let channel = previewOfChannel, !channel.hasChanges, !channel.isDeleted, channel.lastMessageAt == createdAt {
            let cid = channel.cid
            channel.cid = cid
        }

        prepareDefaultSortKeyIfNeeded()
    }

    /// Makes sure the `defaultSortingKey` value is computed and set.
    fileprivate func prepareDefaultSortKeyIfNeeded() {
        let newSortingKey = locallyCreatedAt ?? createdAt
        if defaultSortingKey != newSortingKey {
            defaultSortingKey = newSortingKey
        }
    }
    
    /// Returns a fetch request for messages pending send.
    static func messagesPendingSendFetchRequest() -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.locallyCreatedAt, ascending: true)]

        let pendingSendMessage = NSPredicate(
            format: "localMessageStateRaw == %@", LocalMessageState.pendingSend.rawValue
        )

        let allAttachmentsAreUploadedOrEmpty = NSCompoundPredicate(orPredicateWithSubpredicates: [
            .init(format: "NOT (ANY attachments.localStateRaw != %@)", LocalAttachmentState.uploaded.rawValue),
            .init(format: "attachments.@count == 0")
        ])

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            pendingSendMessage,
            allAttachmentsAreUploadedOrEmpty
        ])

        return request
    }
    
    /// Returns a fetch request for messages pending sync.
    static func messagesPendingSyncFetchRequest() -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.locallyCreatedAt, ascending: true)]
        request.predicate = NSPredicate(format: "localMessageStateRaw == %@", LocalMessageState.pendingSync.rawValue)
        return request
    }
    
    /// Returns a predicate that filters out deleted message by other than the current user
    private static func onlyOwnDeletedMessagesPredicate() -> NSCompoundPredicate {
        .init(orPredicateWithSubpredicates: [
            // Non-deleted messages.
            nonDeletedMessagesPredicate(),
            // Deleted messages sent by current user excluding ephemeral ones.
            NSCompoundPredicate(andPredicateWithSubpredicates: [
                .init(format: "deletedAt != nil"),
                .init(format: "user.currentUser != nil"),
                .init(format: "type != %@", MessageType.ephemeral.rawValue)
            ])
        ])
    }

    private static func deletedMessagesPredicate(
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility
    ) -> NSPredicate {
        let deletedMessagesPredicate: NSPredicate

        switch deletedMessagesVisibility {
        case .alwaysHidden:
            deletedMessagesPredicate = nonDeletedMessagesPredicate()
        case .visibleForCurrentUser:
            deletedMessagesPredicate = onlyOwnDeletedMessagesPredicate()
        case .alwaysVisible:
            deletedMessagesPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                // Non-deleted messages
                nonDeletedMessagesPredicate(),
                // Deleted messages excluding ephemeral ones
                NSPredicate(format: "deletedAt != nil AND type != %@", MessageType.ephemeral.rawValue)
            ])
        }

        let ignoreHardDeletedMessagesPredicate = NSPredicate(
            format: "isHardDeleted == NO"
        )

        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            deletedMessagesPredicate,
            ignoreHardDeletedMessagesPredicate
        ])
    }

    /// Returns a predicate that filters out all deleted messages
    private static func nonDeletedMessagesPredicate() -> NSPredicate {
        .init(format: "deletedAt == nil")
    }
    
    private static func channelPredicate(with cid: String) -> NSPredicate {
        .init(format: "channel.cid == %@", cid)
    }
    
    private static func messageSentPredicate() -> NSPredicate {
        .init(format: "localMessageStateRaw == nil")
    }

    /// Returns predicate for displaying messages after the channel truncation date.
    private static func nonTruncatedMessagesPredicate() -> NSCompoundPredicate {
        .init(orPredicateWithSubpredicates: [
            .init(format: "channel.truncatedAt == nil"),
            .init(format: "createdAt >= channel.truncatedAt")
        ])
    }
    
    /// Returns predicate for the channel preview message.
    private static func previewMessagePredicate(cid: String, includeShadowedMessages: Bool) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            channelMessagesPredicate(
                for: cid,
                deletedMessagesVisibility: .alwaysHidden,
                shouldShowShadowedMessages: includeShadowedMessages
            ),
            .init(format: "type != %@", MessageType.ephemeral.rawValue),
            .init(format: "type != %@", MessageType.error.rawValue)
        ])
    }
    
    /// Returns predicate with channel messages and replies that should be shown in channel.
    static func channelMessagesPredicate(
        for cid: String,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility,
        shouldShowShadowedMessages: Bool
    ) -> NSCompoundPredicate {
        let channelMessagePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            .init(format: "showReplyInChannel == 1"),
            .init(format: "parentMessageId == nil")
        ])

        let validTypes = [
            MessageType.regular.rawValue,
            MessageType.ephemeral.rawValue,
            MessageType.system.rawValue,
            MessageType.deleted.rawValue,
            MessageType.error.rawValue
        ]

        let messageTypePredicate = NSCompoundPredicate(format: "type IN %@", validTypes)

        // Some pinned messages might be in the local database, but should not be fetched
        // if they do not belong to the regular channel query.
        let ignoreOlderMessagesPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            .init(format: "channel.oldestMessageAt == nil"),
            .init(format: "createdAt >= channel.oldestMessageAt")
        ])
        
        var subpredicates = [
            channelPredicate(with: cid),
            channelMessagePredicate,
            messageTypePredicate,
            nonTruncatedMessagesPredicate(),
            ignoreOlderMessagesPredicate,
            deletedMessagesPredicate(deletedMessagesVisibility: deletedMessagesVisibility)
        ]
        
        if !shouldShowShadowedMessages {
            let ignoreShadowedMessages = NSPredicate(format: "isShadowed == NO")
            subpredicates.append(ignoreShadowedMessages)
        }

        return .init(andPredicateWithSubpredicates: subpredicates)
    }
    
    /// Returns predicate with thread messages that should be shown in the thread.
    static func threadRepliesPredicate(
        for messageId: MessageId,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility,
        shouldShowShadowedMessages: Bool
    ) -> NSCompoundPredicate {
        let replyMessage = NSPredicate(format: "parentMessageId == %@", messageId)
        
        var subpredicates = [
            replyMessage,
            deletedMessagesPredicate(deletedMessagesVisibility: deletedMessagesVisibility),
            nonTruncatedMessagesPredicate()
        ]
        
        if !shouldShowShadowedMessages {
            let ignoreShadowedMessages = NSPredicate(format: "isShadowed == NO")
            subpredicates.append(ignoreShadowedMessages)
        }
        
        return .init(andPredicateWithSubpredicates: subpredicates)
    }
    
    /// Returns a fetch request for messages from the channel with the provided `cid`.
    static func messagesFetchRequest(
        for cid: ChannelId,
        sortAscending: Bool = false,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility,
        shouldShowShadowedMessages: Bool
    ) -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: sortAscending)]
        request.predicate = channelMessagesPredicate(
            for: cid.rawValue,
            deletedMessagesVisibility: deletedMessagesVisibility,
            shouldShowShadowedMessages: shouldShowShadowedMessages
        )
        return request
    }
    
    /// Returns a fetch request for replies for the specified `parentMessageId`.
    static func repliesFetchRequest(
        for messageId: MessageId,
        sortAscending: Bool = false,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility,
        shouldShowShadowedMessages: Bool
    ) -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: sortAscending)]
        request.predicate = threadRepliesPredicate(
            for: messageId,
            deletedMessagesVisibility: deletedMessagesVisibility,
            shouldShowShadowedMessages: shouldShowShadowedMessages
        )
        return request
    }
    
    static func messagesFetchRequest(for query: MessageSearchQuery) -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.predicate = NSPredicate(format: "ANY searches.filterHash == %@", query.filterHash)
        let sortDescriptors = query.sort.compactMap { $0.key.sortDescriptor(isAscending: $0.isAscending) }
        request.sortDescriptors = sortDescriptors.isEmpty ? [MessageSearchSortingKey.defaultSortDescriptor] : sortDescriptors
        return request
    }
    
    /// Returns a fetch request for the dto with a specific `messageId`.
    static func message(withID messageId: MessageId) -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: false)]
        request.predicate = NSPredicate(format: "id == %@", messageId)
        return request
    }
    
    static func load(
        for cid: String,
        limit: Int,
        offset: Int = 0,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility,
        shouldShowShadowedMessages: Bool,
        context: NSManagedObjectContext
    ) -> [MessageDTO] {
        let request = NSFetchRequest<MessageDTO>(entityName: entityName)
        request.predicate = channelMessagesPredicate(
            for: cid,
            deletedMessagesVisibility: deletedMessagesVisibility,
            shouldShowShadowedMessages: shouldShowShadowedMessages
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.createdAt, ascending: false)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        return load(by: request, context: context)
    }
    
    static func preview(for cid: String, context: NSManagedObjectContext) -> MessageDTO? {
        let request = NSFetchRequest<MessageDTO>(entityName: entityName)
        request.predicate = previewMessagePredicate(
            cid: cid,
            includeShadowedMessages: context.shouldShowShadowedMessages ?? false
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.createdAt, ascending: false)]
        request.fetchOffset = 0
        request.fetchLimit = 1
        
        return load(by: request, context: context).first
    }
    
    static func load(id: String, context: NSManagedObjectContext) -> MessageDTO? {
        load(by: id, context: context).first
    }
    
    static func loadOrCreate(id: String, context: NSManagedObjectContext, cache: PreWarmedCache?) -> MessageDTO {
        if let cachedObject = cache?.model(for: id, context: context, type: MessageDTO.self) {
            return cachedObject
        }

        if let existing = load(id: id, context: context) {
            return existing
        }
        
        let request = fetchRequest(id: id)
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.id = id
        new.latestReactions = []
        new.ownReactions = []
        return new
    }
    
    /// Load replies for the specified `parentMessageId`.
    static func loadReplies(
        for messageId: MessageId,
        limit: Int,
        offset: Int = 0,
        context: NSManagedObjectContext
    ) -> [MessageDTO] {
        let request = NSFetchRequest<MessageDTO>(entityName: entityName)
        request.predicate = NSPredicate(format: "parentMessageId == %@", messageId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.createdAt, ascending: false)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        return load(by: request, context: context)
    }
    
    static func loadCurrentUserMessages(
        in cid: String,
        createdAtFrom: Date,
        createdAtThrough: Date,
        context: NSManagedObjectContext
    ) -> [MessageDTO] {
        let subpredicates: [NSPredicate] = [
            channelPredicate(with: cid),
            .init(format: "user.currentUser != nil"),
            .init(format: "createdAt > %@", createdAtFrom.bridgeDate),
            .init(format: "createdAt <= %@", createdAtThrough.bridgeDate),
            messageSentPredicate(),
            nonTruncatedMessagesPredicate(),
            nonDeletedMessagesPredicate()
        ]
        
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: false)]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
        
        return (try? context.fetch(request)) ?? []
    }
    
    static func numberOfReads(for messageId: MessageId, context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<ChannelReadDTO>(entityName: ChannelReadDTO.entityName)
        request.predicate = NSPredicate(format: "readMessagesFromCurrentUser.id CONTAINS %@", messageId)
        return (try? context.count(for: request)) ?? 0
    }
    
    static func loadLastMessage(from userId: String, in cid: String, context: NSManagedObjectContext) -> MessageDTO? {
        let request = NSFetchRequest<MessageDTO>(entityName: entityName)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            channelPredicate(with: cid),
            .init(format: "user.id == %@", userId),
            .init(format: "type != %@", MessageType.ephemeral.rawValue),
            messageSentPredicate()
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.createdAt, ascending: false)]
        request.fetchLimit = 1
        return load(by: request, context: context).first
    }
}

extension MessageDTO {
    /// A possible additional local state of the message. Applies only for the messages of the current user.
    var localMessageState: LocalMessageState? {
        get { localMessageStateRaw.flatMap(LocalMessageState.init(rawValue:)) }
        set { localMessageStateRaw = newValue?.rawValue }
    }
}

extension NSManagedObjectContext: MessageDatabaseSession {
    func createNewMessage(
        in cid: ChannelId,
        text: String,
        pinning: MessagePinning?,
        command: String?,
        arguments: String?,
        parentMessageId: MessageId?,
        attachments: [AnyAttachmentPayload],
        mentionedUserIds: [UserId],
        showReplyInChannel: Bool,
        isSilent: Bool,
        quotedMessageId: MessageId?,
        createdAt: Date?,
        extraData: [String: RawJSON]
    ) throws -> MessageDTO {
        guard let currentUserDTO = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }
        
        guard let channelDTO = ChannelDTO.load(cid: cid, context: self) else {
            throw ClientError.ChannelDoesNotExist(cid: cid)
        }

        let message = MessageDTO.loadOrCreate(id: .newUniqueId, context: self, cache: nil)
        
        // We make `createdDate` 0.1 second bigger than Channel's most recent message
        // so if the local time is not in sync, the message will still appear in the correct position
        // even if the sending fails
        let createdAt = createdAt ?? (max(channelDTO.lastMessageAt?.addingTimeInterval(0.1).bridgeDate ?? Date(), Date()))
        message.locallyCreatedAt = createdAt.bridgeDate
        // It's fine that we're saving an incorrect value for `createdAt` and `updatedAt`
        // When message is successfully sent, backend sends the actual dates
        // and these are set correctly in `saveMessage`
        message.createdAt = createdAt.bridgeDate
        message.updatedAt = createdAt.bridgeDate

        if let pinning = pinning {
            try pin(message: message, pinning: pinning)
        }
        
        message.type = parentMessageId == nil ? MessageType.regular.rawValue : MessageType.reply.rawValue
        message.text = text
        message.command = command
        message.args = arguments
        message.parentMessageId = parentMessageId
        message.extraData = try JSONEncoder.default.encode(extraData)
        message.isSilent = isSilent
        message.reactionScores = [:]
        message.reactionCounts = [:]

        message.attachments = Set(
            try attachments.enumerated().map { index, attachment in
                let id = AttachmentId(cid: cid, messageId: message.id, index: index)
                return try createNewAttachment(attachment: attachment, id: id)
            }
        )
        
        // If a user is able to mention someone,
        // most probably we have that user already saved in DB.
        // Ideally, this should be `loadOrCreate` but then
        // we miss non-optional fields of DTO and fail to save.
        message.mentionedUsers = Set(
            mentionedUserIds.compactMap { UserDTO.load(id: $0, context: self) }
        )
                
        message.showReplyInChannel = showReplyInChannel
        message.quotedMessage = quotedMessageId.flatMap { MessageDTO.load(id: $0, context: self) }
        
        message.user = currentUserDTO.user
        message.channel = channelDTO
        
        let newLastMessageAt = max(channelDTO.lastMessageAt?.bridgeDate ?? createdAt, createdAt).bridgeDate
        channelDTO.lastMessageAt = newLastMessageAt
        channelDTO.defaultSortingAt = newLastMessageAt
        
        if let parentMessageId = parentMessageId,
           let parentMessageDTO = MessageDTO.load(id: parentMessageId, context: self) {
            parentMessageDTO.replies.insert(message)
            parentMessageDTO.replyCount += 1
        }
        
        // When the current user submits the new message that will be shown
        // in the channel for sending - make it a channel preview.
        if parentMessageId == nil || showReplyInChannel {
            channelDTO.previewMessage = message
        }
        
        return message
    }

    func saveMessage(
        payload: MessagePayload,
        channelDTO: ChannelDTO,
        syncOwnReactions: Bool,
        cache: PreWarmedCache?
    ) throws -> MessageDTO {
        let cid = try ChannelId(cid: channelDTO.cid)
        let dto = MessageDTO.loadOrCreate(id: payload.id, context: self, cache: cache)

        dto.text = payload.text
        dto.createdAt = payload.createdAt.bridgeDate
        dto.updatedAt = payload.updatedAt.bridgeDate
        dto.deletedAt = payload.deletedAt?.bridgeDate
        dto.type = payload.type.rawValue
        dto.command = payload.command
        dto.args = payload.args
        dto.parentMessageId = payload.parentId
        dto.showReplyInChannel = payload.showReplyInChannel
        dto.replyCount = Int32(payload.replyCount)

        do {
            dto.extraData = try JSONEncoder.default.encode(payload.extraData)
        } catch {
            log.error(
                "Failed to decode extra payload for Message with id: <\(dto.id)>, using default value instead. "
                    + "Error: \(error)"
            )
            dto.extraData = Data()
        }
        
        dto.isSilent = payload.isSilent
        dto.isShadowed = payload.isShadowed
        // Due to backend not working as advertised
        // (sending `shadowed: true` flag to the shadow banned user)
        // we have to implement this workaround to get the advertised behavior
        // info on slack: https://getstream.slack.com/archives/CE5N802GP/p1635785568060500
        // TODO: Remove the workaround once backend bug is fixed
        if currentUser?.user.id == payload.user.id {
            dto.isShadowed = false
        }
        
        dto.pinned = payload.pinned
        dto.pinExpires = payload.pinExpires?.bridgeDate
        dto.pinnedAt = payload.pinnedAt?.bridgeDate
        if let pinnedByUser = payload.pinnedBy {
            dto.pinnedBy = try saveUser(payload: pinnedByUser)
        }
        
        if dto.pinned {
            channelDTO.pinnedMessages.insert(dto)
        } else {
            channelDTO.pinnedMessages.remove(dto)
        }

        if let quotedMessage = payload.quotedMessage {
            dto.quotedMessage = try saveMessage(
                payload: quotedMessage,
                channelDTO: channelDTO,
                syncOwnReactions: false,
                cache: cache
            )
        } else if let quotedMessageId = payload.quotedMessageId {
            // In case we do not have a fully formed quoted message in the payload,
            // we check for quotedMessageId. This can happen in the case of nested quoted messages.
            dto.quotedMessage = message(id: quotedMessageId)
        } else {
            dto.quotedMessage = nil
        }

        let user = try saveUser(payload: payload.user)
        dto.user = user

        dto.reactionScores = payload.reactionScores.mapKeys { $0.rawValue }
        dto.reactionCounts = payload.reactionScores.mapKeys { $0.rawValue }

        // If user edited their message to remove mentioned users, we need to get rid of it
        // as backend does
        dto.mentionedUsers = try Set(payload.mentionedUsers.map {
            let user = try saveUser(payload: $0)
            return user
        })

        // If user participated in thread, but deleted message later, we need to get rid of it if backends does
        dto.threadParticipants = try NSOrderedSet(
            array: payload.threadParticipants.map { try saveUser(payload: $0) }
        )

        channelDTO.lastMessageAt = max(channelDTO.lastMessageAt?.bridgeDate ?? payload.createdAt, payload.createdAt).bridgeDate
        
        dto.channel = channelDTO

        dto.latestReactions = payload
            .latestReactions
            .compactMap { try? saveReaction(payload: $0, cache: cache) }
            .map(\.id)

        if syncOwnReactions {
            dto.ownReactions = payload
                .ownReactions
                .compactMap { try? saveReaction(payload: $0, cache: cache) }
                .map(\.id)
        }

        let attachments: Set<AttachmentDTO> = try Set(
            payload.attachments.enumerated().map { index, attachment in
                let id = AttachmentId(cid: cid, messageId: payload.id, index: index)
                let dto = try saveAttachment(payload: attachment, id: id)
                return dto
            }
        )
        dto.attachments = attachments

        if let parentMessageId = payload.parentId,
           let parentMessageDTO = MessageDTO.load(id: parentMessageId, context: self) {
            parentMessageDTO.replies.insert(dto)
        }
        
        dto.translations = payload.translations?.mapKeys { $0.languageCode }

        // Calculate reads if the message is authored by the current user.
        if payload.user.id == currentUser?.user.id {
            dto.reads = Set(
                channelDTO.reads.filter {
                    $0.lastReadAt.bridgeDate >= payload.createdAt && $0.user.id != payload.user.id
                }
            )
        }
        
        // Refetch channel preview if the current preview has changed.
        //
        // The current messsage can stop being a valid preview e.g.
        // if it didn't pass moderation and obtained `error` type.
        if payload.id == channelDTO.previewMessage?.id {
            channelDTO.previewMessage = preview(for: cid)
        }
        
        return dto
    }

    func saveMessages(messagesPayload: MessageListPayload, for cid: ChannelId?, syncOwnReactions: Bool = true) -> [MessageDTO] {
        let cache = messagesPayload.getPayloadToModelIdMappings(context: self)
        return messagesPayload.messages.compactMapLoggingError {
            try saveMessage(payload: $0, for: cid, syncOwnReactions: syncOwnReactions, cache: cache)
        }
    }

    func saveMessage(
        payload: MessagePayload,
        for cid: ChannelId?,
        syncOwnReactions: Bool = true,
        cache: PreWarmedCache?
    ) throws -> MessageDTO? {
        guard payload.channel != nil || cid != nil else {
            throw ClientError.MessagePayloadSavingFailure("""
            Either `payload.channel` or `cid` must be provided to sucessfuly save the message payload.
            - `payload.channel` value: \(String(describing: payload.channel))
            - `cid` value: \(String(describing: cid))
            """)
        }

        if let cid = cid, let payloadCid = payload.channel?.cid {
            log.assert(cid == payloadCid, "`cid` provided is different from the `payload.channel.cid`.")
        }

        var channelDTO: ChannelDTO?

        if let channelPayload = payload.channel {
            channelDTO = try saveChannel(payload: channelPayload, query: nil, cache: cache)
        } else if let cid = cid {
            channelDTO = ChannelDTO.load(cid: cid, context: self)
        } else {
            log.assertionFailure("Should never happen because either `cid` or `payload.channel` should be present.")
            return nil
        }

        guard let channel = channelDTO else {
            log.assertionFailure("Should never happen, a channel should have been fetched.")
            return nil
        }
        
        return try saveMessage(payload: payload, channelDTO: channel, syncOwnReactions: syncOwnReactions, cache: cache)
    }
    
    func saveMessage(payload: MessagePayload, for query: MessageSearchQuery, cache: PreWarmedCache?) throws -> MessageDTO? {
        guard let messageDTO = try saveMessage(payload: payload, for: nil, cache: cache) else {
            return nil
        }

        messageDTO.searches.insert(saveQuery(query: query))
        return messageDTO
    }
    
    func message(id: MessageId) -> MessageDTO? { .load(id: id, context: self) }
    
    func delete(message: MessageDTO) {
        delete(message)
    }

    func pin(message: MessageDTO, pinning: MessagePinning) throws {
        guard let currentUserDTO = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }
        let pinnedDate = DBDate()
        message.pinned = true
        message.pinnedAt = pinnedDate
        message.pinnedBy = currentUserDTO.user
        message.pinExpires = pinning.expirationDate?.bridgeDate
    }

    func unpin(message: MessageDTO) {
        message.pinned = false
        message.pinnedAt = nil
        message.pinnedBy = nil
        message.pinExpires = nil
    }

    /// Adds the reaction for the current user to the message with id `messageId`
    ///
    /// Notes:
    /// - The reaction is added to the database and it updates the message `reactionScores` property
    /// - This method will throw if there is no current user set
    /// - If the message is not found, there will be no side effect and the method will return `nil`
    /// - If a reaction for the same user, type and message exists
    func addReaction(
        to messageId: MessageId,
        type: MessageReactionType,
        score: Int,
        extraData: [String: RawJSON],
        localState: LocalReactionState?
    ) throws -> MessageReactionDTO {
        guard let currentUserDTO = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }

        guard let message = MessageDTO.load(id: messageId, context: self) else {
            throw ClientError.MessageDoesNotExist(messageId: messageId)
        }

        let dto = MessageReactionDTO.loadOrCreate(
            message: message,
            type: type,
            user: currentUserDTO.user,
            context: self,
            cache: nil
        )

        // make sure we update the reactionScores for the message in a way that works for new or updated reactions
        let scoreDiff = Int64(score) - dto.score
        let newScore = max(0, message.reactionScores[type.rawValue] ?? Int(dto.score) + Int(scoreDiff))
        message.reactionScores[type.rawValue] = newScore

        dto.score = Int64(score)
        dto.extraData = try JSONEncoder.default.encode(extraData)
        dto.localState = localState

        let reactionId = dto.id
        
        if !message.latestReactions.contains(reactionId) {
            message.latestReactions.append(reactionId)
        }

        if !message.ownReactions.contains(reactionId) {
            message.ownReactions.append(reactionId)
        }

        return dto
    }

    /// Removes the reaction for the current user to the message with id `messageId`
    ///
    /// Notes:
    /// - The reaction is *not* removed from the database
    /// - This method will throw if there is no current user set
    /// - If the message is not found, there will be no side effect and the method will return `nil`
    /// - If there is no reaction found in the database, this method returns `nil`
    func removeReaction(from messageId: MessageId, type: MessageReactionType, on version: String?) throws -> MessageReactionDTO? {
        guard let currentUserDTO = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }

        guard let message = MessageDTO.load(id: messageId, context: self) else {
            throw ClientError.MessageDoesNotExist(messageId: messageId)
        }

        guard let reaction = MessageReactionDTO
            .load(userId: currentUserDTO.user.id, messageId: messageId, type: type, context: self) else {
            return nil
        }

        // if the reaction on the database does not match the version, do nothing
        guard version == nil || version == reaction.version else {
            return nil
        }
        
        message.latestReactions = message.latestReactions.filter { $0 != reaction.id }
        message.ownReactions = message.ownReactions.filter { $0 != reaction.id }

        guard let reactionScore = message.reactionScores.removeValue(forKey: type.rawValue), reactionScore > 1 else {
            return reaction
        }

        message.reactionScores[type.rawValue] = max(reactionScore - Int(reaction.score), 0)
        return reaction
    }
    
    func preview(for cid: ChannelId) -> MessageDTO? {
        MessageDTO.preview(for: cid.rawValue, context: self)
    }

    func saveMessageSearch(payload: MessageSearchResultsPayload, for query: MessageSearchQuery) -> [MessageDTO] {
        let cache = payload.getPayloadToModelIdMappings(context: self)
        return payload.results.compactMapLoggingError {
            try saveMessage(payload: $0.message, for: query, cache: cache)
        }
    }
}

extension MessageDTO {
    /// Snapshots the current state of `MessageDTO` and returns an immutable model object from it.
    func asModel() throws -> ChatMessage { try .init(fromDTO: self) }
    
    /// Snapshots the current state of `MessageDTO` and returns its representation for the use in API calls.
    func asRequestBody() -> MessageRequestBody {
        var decodedExtraData: [String: RawJSON]
        
        if let extraData = self.extraData {
            do {
                decodedExtraData = try JSONDecoder.default.decode([String: RawJSON].self, from: extraData)
            } catch {
                log.assertionFailure(
                    "Failed decoding saved extra data with error: \(error). This should never happen because"
                        + "the extra data must be a valid JSON to be saved."
                )
                decodedExtraData = [:]
            }
        } else {
            decodedExtraData = [:]
        }
        
        return .init(
            id: id,
            user: user.asRequestBody(),
            text: text,
            command: command,
            args: args,
            parentId: parentMessageId,
            showReplyInChannel: showReplyInChannel,
            isSilent: isSilent,
            quotedMessageId: quotedMessage?.id,
            attachments: attachments
                .sorted { $0.attachmentID.index < $1.attachmentID.index }
                .compactMap { $0.asRequestPayload() },
            mentionedUserIds: mentionedUsers.map(\.id),
            pinned: pinned,
            pinExpires: pinExpires?.bridgeDate,
            extraData: decodedExtraData
        )
    }
}

private extension ChatMessage {
    init(fromDTO dto: MessageDTO) throws {
        guard dto.isValid, let context = dto.managedObjectContext else {
            throw InvalidModel(dto)
        }
        
        id = dto.id
        cid = try? dto.channel.map { try ChannelId(cid: $0.cid) }
        text = dto.text
        type = MessageType(rawValue: dto.type) ?? .regular
        command = dto.command
        createdAt = dto.createdAt.bridgeDate
        locallyCreatedAt = dto.locallyCreatedAt?.bridgeDate
        updatedAt = dto.updatedAt.bridgeDate
        deletedAt = dto.deletedAt?.bridgeDate
        arguments = dto.args
        parentMessageId = dto.parentMessageId
        showReplyInChannel = dto.showReplyInChannel
        replyCount = Int(dto.replyCount)
        isSilent = dto.isSilent
        isShadowed = dto.isShadowed
        reactionScores = dto.reactionScores.mapKeys { MessageReactionType(rawValue: $0) }
        reactionCounts = dto.reactionCounts.mapKeys { MessageReactionType(rawValue: $0) }
        translations = dto.translations?.mapKeys { TranslationLanguage(languageCode: $0) }
                
        if let extraData = dto.extraData, !extraData.isEmpty {
            do {
                self.extraData = try JSONDecoder.default.decode([String: RawJSON].self, from: extraData)
            } catch {
                log
                    .error(
                        "Failed to decode extra data for Message with id: <\(dto.id)>, using default value instead. Error: \(error)"
                    )
                self.extraData = [:]
            }
        } else {
            extraData = [:]
        }

        localState = dto.localMessageState
        isFlaggedByCurrentUser = dto.flaggedBy != nil
        
        if dto.pinned,
           let pinnedAt = dto.pinnedAt,
           let pinnedBy = dto.pinnedBy {
            pinDetails = try .init(
                pinnedAt: pinnedAt.bridgeDate,
                pinnedBy: pinnedBy.asModel(),
                expiresAt: dto.pinExpires?.bridgeDate
            )
        } else {
            pinDetails = nil
        }

        if let currentUser = context.currentUser {
            isSentByCurrentUser = currentUser.user.id == dto.user.id
            $_currentUserReactions = ({
                Set(
                    MessageReactionDTO
                        .loadReactions(ids: dto.ownReactions, context: context)
                        .compactMap { try? $0.asModel() }
                )
            }, dto.managedObjectContext)
        } else {
            isSentByCurrentUser = false
            $_currentUserReactions = ({ [] }, nil)
        }
        
        $_latestReactions = ({
            Set(
                MessageReactionDTO
                    .loadReactions(ids: dto.latestReactions, context: context)
                    .compactMap { try? $0.asModel() }
            )
        }, dto.managedObjectContext)

        if dto.threadParticipants.array.isEmpty {
            $_threadParticipants = ({ [] }, nil)
        } else {
            $_threadParticipants = (
                {
                    let threadParticipants = dto.threadParticipants.array as? [UserDTO] ?? []
                    return threadParticipants.compactMap { try? $0.asModel() }
                },
                dto.managedObjectContext
            )
        }
        
        $_mentionedUsers = ({ Set(dto.mentionedUsers.compactMap { try? $0.asModel() }) }, dto.managedObjectContext)

        let user = try dto.user.asModel()
        $_author = ({ user }, nil)
        $_attachments = ({
            dto.attachments
                .map { $0.asAnyModel() }
                .sorted { $0.id.index < $1.id.index }
        }, dto.managedObjectContext)
        
        if dto.replies.isEmpty {
            $_latestReplies = ({ [] }, nil)
        } else {
            $_latestReplies = ({
                MessageDTO
                    .loadReplies(for: dto.id, limit: 5, context: context)
                    .compactMap { try? ChatMessage(fromDTO: $0) }
            }, dto.managedObjectContext)
        }

        $_quotedMessage = ({ try? dto.quotedMessage?.asModel() }, dto.managedObjectContext)
        let readBy = {
            Set(dto.reads.compactMap { try? $0.user.asModel() })
        }
        
        $_readBy = (readBy, dto.managedObjectContext)
        
        let readByCount = {
            MessageDTO.numberOfReads(for: dto.id, context: context)
        }
        
        $_readByCount = (readByCount, dto.managedObjectContext)
    }
}

extension ClientError {
    class CurrentUserDoesNotExist: ClientError {
        override var localizedDescription: String {
            "There is no `CurrentUserDTO` instance in the DB."
                + "Make sure to call `client.currentUserController.reloadUserIfNeeded()`"
        }
    }

    class MessagePayloadSavingFailure: ClientError {}

    class ChannelDoesNotExist: ClientError {
        init(cid: ChannelId) {
            super.init("There is no `ChannelDTO` instance in the DB matching cid: \(cid).")
        }
    }
}
