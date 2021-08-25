//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var deletedAt: Date?
    @NSManaged var args: String?
    @NSManaged var parentMessageId: MessageId?
    @NSManaged var showReplyInChannel: Bool
    @NSManaged var replyCount: Int32
    @NSManaged var extraData: Data
    @NSManaged var isSilent: Bool
    @NSManaged var reactionScores: [String: Int]
    
    @NSManaged var user: UserDTO
    @NSManaged var mentionedUsers: Set<UserDTO>
    @NSManaged var threadParticipants: NSOrderedSet
    @NSManaged var channel: ChannelDTO?
    @NSManaged var replies: Set<MessageDTO>
    @NSManaged var flaggedBy: CurrentUserDTO?
    @NSManaged var reactions: Set<MessageReactionDTO>
    @NSManaged var attachments: Set<AttachmentDTO>
    @NSManaged var quotedMessage: MessageDTO?

    @NSManaged var pinned: Bool
    @NSManaged var pinnedBy: UserDTO?
    @NSManaged var pinnedAt: Date?
    @NSManaged var pinExpires: Date?

    // The timestamp the message was created locally. Applies only for the messages of the current user.
    @NSManaged var locallyCreatedAt: Date?
    
    // We use `Date!` to replicate a required value. The value must be marked as optional in the CoreData model, because we change
    // it in the `willSave` phase, which happens after the validation.
    @NSManaged var defaultSortingKey: Date!
    
    override func willSave() {
        super.willSave()
        
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
            .init(format: "deletedAt == nil"),
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
            deletedMessagesPredicate = NSPredicate(value: true) // an empty predicate to avoid optionals
        }
        return deletedMessagesPredicate
    }

    /// Returns a predicate that filters out all deleted messages
    private static func nonDeletedMessagesPredicate() -> NSCompoundPredicate {
        .init(format: "deletedAt == nil")
    }

    /// Returns predicate for displaying messages after the channel truncation date.
    private static func nonTruncatedMessagesPredicate() -> NSCompoundPredicate {
        .init(orPredicateWithSubpredicates: [
            .init(format: "channel.truncatedAt == nil"),
            .init(format: "createdAt > channel.truncatedAt")
        ])
    }
    
    /// Returns predicate with channel messages and replies that should be shown in channel.
    static func channelMessagesPredicate(
        for cid: String,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility
    ) -> NSCompoundPredicate {
        let channelMessage = NSPredicate(
            format: "channel.cid == %@", cid
        )

        let messageTypePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            .init(format: "type != %@", MessageType.reply.rawValue),
            .init(format: "type == %@ AND showReplyInChannel == 1", MessageType.reply.rawValue)
        ])
        
        // Some pinned messages might be in the local database, but should not be fetched
        // if they do not belong to the regular channel query.
        let ignoreOlderMessagesPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            .init(format: "channel.oldestMessageAt == nil"),
            .init(format: "createdAt >= channel.oldestMessageAt")
        ])

        return .init(andPredicateWithSubpredicates: [
            channelMessage,
            messageTypePredicate,
            nonTruncatedMessagesPredicate(),
            ignoreOlderMessagesPredicate,
            deletedMessagesPredicate(deletedMessagesVisibility: deletedMessagesVisibility)
        ])
    }
    
    /// Returns predicate with thread messages that should be shown in the thread.
    static func threadRepliesPredicate(
        for messageId: MessageId,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility
    ) -> NSCompoundPredicate {
        let replyMessage = NSPredicate(format: "parentMessageId == %@", messageId)
        
        return .init(andPredicateWithSubpredicates: [
            replyMessage,
            deletedMessagesPredicate(deletedMessagesVisibility: deletedMessagesVisibility),
            nonTruncatedMessagesPredicate()
        ])
    }
    
    /// Returns a fetch request for messages from the channel with the provided `cid`.
    static func messagesFetchRequest(
        for cid: ChannelId,
        sortAscending: Bool = false,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility
    ) -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: sortAscending)]
        request.predicate = channelMessagesPredicate(for: cid.rawValue, deletedMessagesVisibility: deletedMessagesVisibility)
        return request
    }
    
    /// Returns a fetch request for replies for the specified `parentMessageId`.
    static func repliesFetchRequest(
        for messageId: MessageId,
        sortAscending: Bool = false,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility
    ) -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: sortAscending)]
        request.predicate = threadRepliesPredicate(for: messageId, deletedMessagesVisibility: deletedMessagesVisibility)
        return request
    }
    
    /// Returns a fetch request for the dto with a specific `messageId`.
    static func message(withID messageId: MessageId) -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: false)]
        request.predicate = NSPredicate(format: "id == %@", messageId)
        return request
    }
    
    static func load(for cid: String, limit: Int, offset: Int = 0, context: NSManagedObjectContext) -> [MessageDTO] {
        let request = NSFetchRequest<MessageDTO>(entityName: entityName)
        request.predicate = channelMessagesPredicate(
            for: cid,
            deletedMessagesVisibility: context.deletedMessagesVisibility ?? .visibleForCurrentUser
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.createdAt, ascending: false)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        return load(by: request, context: context)
    }
    
    static func load(id: String, context: NSManagedObjectContext) -> MessageDTO? {
        let request = NSFetchRequest<MessageDTO>(entityName: entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        return load(by: request, context: context).first
    }
    
    static func loadOrCreate(id: String, context: NSManagedObjectContext) -> MessageDTO {
        if let existing = load(id: id, context: context) {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as! Self
        new.id = id
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

    static func loadAttachmentCounts(
        for messageId: MessageId,
        context: NSManagedObjectContext
    ) -> [AttachmentType: Int] {
        enum AttachmentScoreKey: String {
            case type
            case count
        }

        let count = NSExpressionDescription()
        count.name = AttachmentScoreKey.count.rawValue
        count.expressionResultType = .integer64AttributeType
        count.expression = NSExpression(
            forFunction: "count:",
            arguments: [NSExpression(forKeyPath: AttachmentScoreKey.type.rawValue)]
        )

        let request = NSFetchRequest<NSDictionary>(entityName: AttachmentDTO.entityName)
        request.propertiesToFetch = [AttachmentScoreKey.type.rawValue, count]
        request.propertiesToGroupBy = [AttachmentScoreKey.type.rawValue]
        request.resultType = .dictionaryResultType
        request.predicate = NSPredicate(
            format: "%K.%K == %@",
            #keyPath(AttachmentDTO.message),
            #keyPath(MessageDTO.id),
            messageId
        )

        do {
            return try context.fetch(request).reduce(into: [:]) { counts, entry in
                guard
                    let type = entry.value(forKey: AttachmentScoreKey.type.rawValue) as? String,
                    let count = entry.value(forKey: AttachmentScoreKey.count.rawValue) as? Int
                else { return }

                counts[.init(rawValue: type)] = count
            }
        } catch {
            log.error("Failed to fetch attachment counts for the message with id: \(messageId), error: \(error)")
            return [:]
        }
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
        
        let message = MessageDTO.loadOrCreate(id: .newUniqueId, context: self)
        
        // We make `createdDate` 0.1 second bigger than Channel's most recent message
        // so if the local time is not in sync, the message will still appear in the correct position
        // even if the sending fails
        let createdAt = createdAt ?? (max(channelDTO.lastMessageAt?.addingTimeInterval(0.1) ?? Date(), Date()))
        message.locallyCreatedAt = createdAt
        // It's fine that we're saving an incorrect value for `createdAt` and `updatedAt`
        // When message is successfully sent, backend sends the actual dates
        // and these are set correctly in `saveMessage`
        message.createdAt = createdAt
        message.updatedAt = createdAt

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
        
        let newLastMessageAt = max(channelDTO.lastMessageAt ?? createdAt, createdAt)
        channelDTO.lastMessageAt = newLastMessageAt
        channelDTO.defaultSortingAt = newLastMessageAt
        
        if let parentMessageId = parentMessageId,
           let parentMessageDTO = MessageDTO.load(id: parentMessageId, context: self) {
            parentMessageDTO.replies.insert(message)
        }
        
        return message
    }
    
    func saveMessage(payload: MessagePayload, for cid: ChannelId?) throws -> MessageDTO {
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
        
        let dto = MessageDTO.loadOrCreate(id: payload.id, context: self)

        dto.text = payload.text
        dto.createdAt = payload.createdAt
        dto.updatedAt = payload.updatedAt
        dto.deletedAt = payload.deletedAt
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
        dto.pinned = payload.pinned
        dto.pinExpires = payload.pinExpires
        dto.pinnedAt = payload.pinnedAt
        if let pinnedByUser = payload.pinnedBy {
            dto.pinnedBy = try saveUser(payload: pinnedByUser)
        }

        if let quotedMessage = payload.quotedMessage {
            dto.quotedMessage = try saveMessage(payload: quotedMessage, for: cid)
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

        var channelDTO: ChannelDTO?

        if let channelPayload = payload.channel {
            channelDTO = try saveChannel(payload: channelPayload, query: nil)
        } else if let cid = cid {
            channelDTO = ChannelDTO.load(cid: cid, context: self)
        } else {
            log.assertionFailure("Should never happen because either `cid` or `payload.channel` should be present.")
        }

        if let channelDTO = channelDTO {
            channelDTO.lastMessageAt = max(channelDTO.lastMessageAt ?? payload.createdAt, payload.createdAt)
            
            if dto.pinned {
                channelDTO.pinnedMessages.insert(dto)
            } else {
                channelDTO.pinnedMessages.remove(dto)
            }
            
            dto.channel = channelDTO
        } else {
            log.assertionFailure("Should never happen, a channel should have been fetched.")
        }
        
        let reactions = payload.latestReactions + payload.ownReactions
        try reactions.forEach { try saveReaction(payload: $0) }
        
        let cid = cid ?? payload.channel!.cid
        
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

        dto.pinned = payload.pinned
        dto.pinnedAt = payload.pinnedAt
        dto.pinExpires = payload.pinExpires
        if let pinnedBy = payload.pinnedBy {
            dto.pinnedBy = try saveUser(payload: pinnedBy)
        }
        
        return dto
    }
    
    func message(id: MessageId) -> MessageDTO? { .load(id: id, context: self) }
    
    func delete(message: MessageDTO) {
        delete(message)
    }

    func pin(message: MessageDTO, pinning: MessagePinning) throws {
        guard let currentUserDTO = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }
        let pinnedDate = Date()
        message.pinned = true
        message.pinnedAt = pinnedDate
        message.pinnedBy = currentUserDTO.user
        message.pinExpires = pinning.expirationDate
    }

    func unpin(message: MessageDTO) {
        message.pinned = false
        message.pinnedAt = nil
        message.pinnedBy = nil
        message.pinExpires = nil
    }
}

extension MessageDTO {
    /// Snapshots the current state of `MessageDTO` and returns an immutable model object from it.
    func asModel() -> ChatMessage { .init(fromDTO: self) }
    
    /// Snapshots the current state of `MessageDTO` and returns its representation for the use in API calls.
    func asRequestBody() -> MessageRequestBody {
        var extraData: [String: RawJSON]
        do {
            extraData = try JSONDecoder.default.decode([String: RawJSON].self, from: self.extraData)
        } catch {
            log.assertionFailure(
                "Failed decoding saved extra data with error: \(error). This should never happen because"
                    + "the extra data must be a valid JSON to be saved."
            )
            extraData = [:]
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
            pinExpires: pinExpires,
            extraData: extraData
        )
    }
}

private extension ChatMessage {
    init(fromDTO dto: MessageDTO) {
        let context = dto.managedObjectContext!
        
        id = dto.id
        cid = dto.channel.map { try! ChannelId(cid: $0.cid) }
        text = dto.text
        type = MessageType(rawValue: dto.type) ?? .regular
        command = dto.command
        createdAt = dto.createdAt
        locallyCreatedAt = dto.locallyCreatedAt
        updatedAt = dto.updatedAt
        deletedAt = dto.deletedAt
        arguments = dto.args
        parentMessageId = dto.parentMessageId
        showReplyInChannel = dto.showReplyInChannel
        replyCount = Int(dto.replyCount)
        isSilent = dto.isSilent
        reactionScores = dto.reactionScores.mapKeys { MessageReactionType(rawValue: $0) }
        
        do {
            extraData = try JSONDecoder.default.decode([String: RawJSON].self, from: dto.extraData)
        } catch {
            log.error("Failed to decode extra data for Message with id: <\(dto.id)>, using default value instead. Error: \(error)")
            extraData = [:]
        }

        localState = dto.localMessageState
        isFlaggedByCurrentUser = dto.flaggedBy != nil
        
        if dto.pinned,
           let pinnedAt = dto.pinnedAt,
           let pinnedBy = dto.pinnedBy,
           let pinExpires = dto.pinExpires {
            pinDetails = .init(
                pinnedAt: pinnedAt,
                pinnedBy: pinnedBy.asModel(),
                expiresAt: pinExpires
            )
        } else {
            pinDetails = nil
        }
        
        if let currentUser = context.currentUser {
            isSentByCurrentUser = currentUser.user.id == dto.user.id
            
            if dto.reactions.isEmpty {
                $_currentUserReactions = ({ [] }, nil)
            } else {
                $_currentUserReactions = ({
                    Set(
                        MessageReactionDTO
                            .loadReactions(for: dto.id, authoredBy: currentUser.user.id, context: context)
                            .map { $0.asModel() }
                    )
                }, dto.managedObjectContext)
            }
        } else {
            isSentByCurrentUser = false
            $_currentUserReactions = ({ [] }, nil)
        }
        
        if dto.threadParticipants.array.isEmpty {
            $_threadParticipants = ({ [] }, nil)
        } else {
            $_threadParticipants = (
                {
                    let threadParticipants = dto.threadParticipants.array as? [UserDTO] ?? []
                    return threadParticipants.map { $0.asModel() }
                },
                dto.managedObjectContext
            )
        }
        
        $_mentionedUsers = ({ Set(dto.mentionedUsers.map { $0.asModel() }) }, dto.managedObjectContext)
        $_author = ({ dto.user.asModel() }, dto.managedObjectContext)
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
                    .map(ChatMessage.init)
            }, dto.managedObjectContext)
        }
        
        if dto.reactions.isEmpty {
            $_latestReactions = ({ [] }, nil)
        } else {
            $_latestReactions = ({
                Set(
                    MessageReactionDTO
                        .loadLatestReactions(for: dto.id, limit: 5, context: context)
                        .map { $0.asModel() }
                )
            }, dto.managedObjectContext)
        }
        
        $_quotedMessage = ({ dto.quotedMessage?.asModel() }, dto.managedObjectContext)

        $_attachmentCounts = ({ [id] in
            MessageDTO.loadAttachmentCounts(for: id, context: context)
        }, context)
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
