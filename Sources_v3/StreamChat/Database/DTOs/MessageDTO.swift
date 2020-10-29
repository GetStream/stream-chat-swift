//
// Copyright © 2020 Stream.io Inc. All rights reserved.
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
    @NSManaged var channel: ChannelDTO
    @NSManaged var replies: Set<MessageDTO>
    @NSManaged var flaggedBy: CurrentUserDTO?
    @NSManaged var reactions: Set<MessageReactionDTO>
    @NSManaged var attachments: Set<AttachmentDTO>
    
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
        request.predicate = NSPredicate(format: "localMessageStateRaw == %@", LocalMessageState.pendingSend.rawValue)
        return request
    }
    
    /// Returns a fetch request for messages pending sync.
    static func messagesPendingSyncFetchRequest() -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.locallyCreatedAt, ascending: true)]
        request.predicate = NSPredicate(format: "localMessageStateRaw == %@", LocalMessageState.pendingSync.rawValue)
        return request
    }
    
    /// Returns predicate with channel messages and replies that should be shown in channel.
    static func channelMessagesPredicate(for cid: String) -> NSCompoundPredicate {
        /// Channel messages.
        let messagesPredicate = NSPredicate(format: "channel.cid == %@ AND type != %@", cid, MessageType.reply.rawValue)
        /// Replies that should be shown in channel.
        let repliesPredicate = NSPredicate(
            format: "channel.cid == %@ AND type == %@ AND showReplyInChannel == 1", cid, MessageType.reply.rawValue
        )
        return .init(orPredicateWithSubpredicates: [messagesPredicate, repliesPredicate])
    }
    
    /// Returns a fetch request for messages from the channel with the provided `cid`.
    static func messagesFetchRequest(for cid: ChannelId, sortAscending: Bool = false) -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: sortAscending)]
        request.predicate = channelMessagesPredicate(for: cid.rawValue)
        return request
    }
    
    /// Returns a fetch request for replies for the specified `parentMessageId`.
    static func repliesFetchRequest(for messageId: MessageId, sortAscending: Bool = false) -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: sortAscending)]
        request.predicate = NSPredicate(format: "parentMessageId == %@", messageId)
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
        request.predicate = channelMessagesPredicate(for: cid)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.createdAt, ascending: false)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        return try! context.fetch(request)
    }
    
    static func load(id: String, context: NSManagedObjectContext) -> MessageDTO? {
        let request = NSFetchRequest<MessageDTO>(entityName: entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        return try! context.fetch(request).first
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
        return try! context.fetch(request)
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
    func createNewMessage<ExtraData: MessageExtraData>(
        in cid: ChannelId,
        text: String,
        command: String?,
        arguments: String?,
        parentMessageId: MessageId?,
        showReplyInChannel: Bool,
        extraData: ExtraData
    ) throws -> MessageDTO {
        guard let currentUserDTO = currentUser() else {
            throw ClientError.CurrentUserDoesNotExist()
        }
        
        guard let channelDTO = ChannelDTO.load(cid: cid, context: self) else {
            throw ClientError.ChannelDoesNotExist(cid: cid)
        }
        
        let message = MessageDTO.loadOrCreate(id: .newUniqueId, context: self)
        
        let createdDate = Date()
        message.createdAt = createdDate
        message.locallyCreatedAt = createdDate
        message.updatedAt = createdDate
        
        message.type = parentMessageId == nil ? MessageType.regular.rawValue : MessageType.reply.rawValue
        message.text = text
        message.command = command
        message.args = arguments
        message.parentMessageId = parentMessageId
        message.extraData = try JSONEncoder.default.encode(extraData)
        message.isSilent = false
        message.reactionScores = [:]
        message.attachments = try Set(attachments.map { try saveAttachment(attachment: $0, messageId: message.id, cid: cid) })
        message.showReplyInChannel = showReplyInChannel
        
        message.user = currentUserDTO.user
        message.channel = channelDTO
        
        if let parentMessageId = parentMessageId,
            let parentMessageDTO = MessageDTO.load(id: parentMessageId, context: self) {
            parentMessageDTO.replies.insert(message)
        }
        
        return message
    }
    
    func saveMessage<ExtraData: ExtraDataTypes>(payload: MessagePayload<ExtraData>, for cid: ChannelId) throws -> MessageDTO {
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
        dto.extraData = try JSONEncoder.default.encode(payload.extraData)
        dto.isSilent = payload.isSilent
        dto.channel = ChannelDTO.loadOrCreate(cid: cid, context: self)
        
        let user = try saveUser(payload: payload.user)
        dto.user = user
        
        dto.reactionScores = payload.reactionScores.mapKeys { $0.rawValue }
        let reactions = payload.latestReactions + payload.ownReactions
        try reactions.forEach { try saveReaction(payload: $0) }
        
        try payload.mentionedUsers.forEach { userPayload in
            let user = try saveUser(payload: userPayload)
            dto.mentionedUsers.insert(user)
        }
        
        try payload.attachments.forEach { attachmentPayload in
            let attachment = try saveAttachment(payload: attachmentPayload, messageId: payload.id, cid: cid)
            dto.attachments.insert(attachment)
        }
        
        if let parentMessageId = payload.parentId,
            let parentMessageDTO = MessageDTO.load(id: parentMessageId, context: self) {
            parentMessageDTO.replies.insert(dto)
        }
        
        return dto
    }
    
    func message(id: MessageId) -> MessageDTO? { .load(id: id, context: self) }
    
    func delete(message: MessageDTO) {
        delete(message)
    }
}

extension MessageDTO {
    /// Snapshots the current state of `MessageDTO` and returns an immutable model object from it.
    func asModel<ExtraData: ExtraDataTypes>() -> _ChatMessage<ExtraData> { .init(fromDTO: self) }
    
    /// Snapshots the current state of `MessageDTO` and returns its representation for the use in API calls.
    func asRequestBody<ExtraData: ExtraDataTypes>() -> MessageRequestBody<ExtraData> {
        var extraData: ExtraData.Message?
        do {
            extraData = try JSONDecoder.default.decode(ExtraData.Message.self, from: self.extraData)
        } catch {
            log.assertationFailure(
                "Failed decoding saved extra data with error: \(error). This should never happen because"
                    + "the extra data must be a valid JSON to be saved."
            )
        }
        
        return .init(
            id: id,
            user: user.asRequestBody(),
            text: text,
            command: command,
            args: args,
            parentId: parentMessageId,
            showReplyInChannel: showReplyInChannel,
            attachments: attachments.map { $0.asRequestPayload() },
            extraData: extraData ?? .defaultValue
        )
    }
}

extension _ChatMessage {
    fileprivate init(fromDTO dto: MessageDTO) {
        let context = dto.managedObjectContext!
        
        id = dto.id
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
        
        let extraData: ExtraData.Message
        do {
            extraData = try JSONDecoder.default.decode(ExtraData.Message.self, from: dto.extraData)
        } catch {
            log.error("Failed to decode extra data for Message with id: <\(dto.id)>, using default value instead. Error: \(error)")
            extraData = .defaultValue
        }
        self.extraData = extraData
        
        author = dto.user.asModel()
        mentionedUsers = Set(dto.mentionedUsers.map { $0.asModel() })

        latestReplies = MessageDTO
            .loadReplies(for: dto.id, limit: 25, context: context)
            .map(_ChatMessage.init)
        
        localState = dto.localMessageState
        
        isFlaggedByCurrentUser = dto.flaggedBy != nil
        
        latestReactions = Set(
            MessageReactionDTO
                .loadLatestReactions(for: dto.id, limit: 10, context: context)
                .map { $0.asModel() }
        )
        
        if let currentUser = context.currentUser() {
            currentUserReactions = Set(
                MessageReactionDTO
                    .loadReactions(for: dto.id, authoredBy: currentUser.user.id, context: context)
                    .map { $0.asModel() }
            )
        } else {
            currentUserReactions = []
        }
    }
}

extension ClientError {
    class CurrentUserDoesNotExist: ClientError {
        override var localizedDescription: String {
            "There is no `CurrentUserDTO` instance in the DB. Make sure to call `Client.setUser`."
        }
    }
    
    class ChannelDoesNotExist: ClientError {
        init(cid: ChannelId) {
            super.init("There is no `ChannelDTO` instance in the DB matching cid: \(cid).")
        }
    }
}
