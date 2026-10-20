//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ScheduledMessageDTO)
class ScheduledMessageDTO: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var cid: String
    @NSManaged var status: String
    @NSManaged var failureReason: String?
    @NSManaged var scheduledAt: DBDate
    @NSManaged var createdAt: DBDate
    @NSManaged var updatedAt: DBDate

    // A helper property used for sorting the pending messages before the failed ones.
    @NSManaged var isPending: Bool

    // Whether `scheduledAt` was changed locally and is not on the server yet.
    @NSManaged var hasPendingScheduledAt: Bool

    // Why the latest local changes could not be sent to the server, from the error of the server.
    @NSManaged var localErrorReason: String?
    @NSManaged var localErrorMessage: String?

    // The quoted message is not always available locally, so its id is kept.
    @NSManaged var quotedMessageId: String?

    // The backend only returns the channel in query results, so the last known one is kept.
    @NSManaged var channelName: String?
    @NSManaged var channelImageURL: URL?

    // Relationships

    // The content of the message, with its local state and attachments, like any other message.
    @NSManaged var message: MessageDTO?

    override func willSave() {
        super.willSave()

        let newIsPending = ScheduledMessageStatus(rawValue: status) != .failed
        if isPending != newIsPending {
            isPending = newIsPending
        }
    }

    /// Returns a fetch request for the scheduled message with the provided id.
    static func fetchRequest(id: String) -> NSFetchRequest<ScheduledMessageDTO> {
        let request = NSFetchRequest<ScheduledMessageDTO>(entityName: ScheduledMessageDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ScheduledMessageDTO.scheduledAt, ascending: true)]
        return request
    }

    /// Returns a fetch request for scheduled messages based on the provided query.
    static func scheduledMessagesFetchRequest(query: ScheduledMessageListQuery) -> NSFetchRequest<ScheduledMessageDTO> {
        let request = NSFetchRequest<ScheduledMessageDTO>(entityName: ScheduledMessageDTO.entityName)
        ScheduledMessageDTO.applyPrefetchingState(to: request)

        var sortDescriptors: [NSSortDescriptor] = []
        for sorting in query.sort {
            switch sorting.key {
            case .scheduledAt:
                sortDescriptors.append(NSSortDescriptor(keyPath: \ScheduledMessageDTO.scheduledAt, ascending: sorting.isAscending))
            case .createdAt:
                sortDescriptors.append(NSSortDescriptor(keyPath: \ScheduledMessageDTO.createdAt, ascending: sorting.isAscending))
            default:
                continue
            }
        }
        // Without a sorting, pending messages come first and failed ones after, each sorted by `scheduledAt`.
        if sortDescriptors.isEmpty {
            sortDescriptors = [
                NSSortDescriptor(keyPath: \ScheduledMessageDTO.isPending, ascending: false),
                NSSortDescriptor(keyPath: \ScheduledMessageDTO.scheduledAt, ascending: true)
            ]
        }
        request.sortDescriptors = sortDescriptors

        if let filter = query.filter, let predicate = filter.predicate {
            request.predicate = predicate
        }

        return request
    }

    /// Returns a fetch request for the scheduled messages with local changes to send to the server,
    /// once all their attachments are uploaded.
    static func pendingRequestsFetchRequest() -> NSFetchRequest<ScheduledMessageDTO> {
        let request = NSFetchRequest<ScheduledMessageDTO>(entityName: ScheduledMessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ScheduledMessageDTO.createdAt, ascending: true)]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(
                format: "message.localMessageStateRaw IN %@",
                [LocalMessageState.pendingSend.rawValue, LocalMessageState.pendingSync.rawValue]
            ),
            NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(
                    format: "SUBQUERY(message.attachments, $a, $a.localStateRaw == %@).@count == message.attachments.@count",
                    LocalAttachmentState.uploaded.rawValue
                ),
                NSPredicate(format: "SUBQUERY(message.attachments, $a, $a.localStateRaw == nil).@count == message.attachments.@count")
            ])
        ])
        return request
    }

    /// Loads the scheduled message with the specified id.
    static func load(id: String, context: NSManagedObjectContext) -> ScheduledMessageDTO? {
        load(by: fetchRequest(id: id), context: context).first
    }

    /// Loads or creates the scheduled message with the specified id.
    static func loadOrCreate(id: String, context: NSManagedObjectContext) -> ScheduledMessageDTO {
        if let existing = load(id: id, context: context) {
            return existing
        }

        let request = fetchRequest(id: id)
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.id = id
        return new
    }

    /// Whether the scheduled message was created locally and is not on the server yet.
    var isLocalOnly: Bool {
        switch message?.localMessageState {
        case .pendingSend, .sending, .sendingFailed:
            return true
        default:
            return false
        }
    }

    /// Whether the scheduled message has local changes the server does not have yet.
    var hasLocalChanges: Bool {
        switch message?.localMessageState {
        case .pendingSend, .sending, .pendingSync, .syncing:
            return true
        default:
            return false
        }
    }
}

extension NSManagedObjectContext: ScheduledMessageDatabaseSession {
    func createNewScheduledMessage(
        id: String,
        cid: ChannelId,
        content: ScheduledMessageContent,
        scheduledAt: Date
    ) throws -> ScheduledMessageDTO {
        guard let currentUserDTO = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }

        let now = Date()
        let dto = ScheduledMessageDTO.loadOrCreate(id: id, context: self)
        dto.cid = cid.rawValue
        dto.status = ScheduledMessageStatus.scheduled.rawValue
        dto.failureReason = nil
        dto.localErrorReason = nil
        dto.localErrorMessage = nil
        dto.scheduledAt = scheduledAt.bridgeDate
        dto.createdAt = now.bridgeDate
        dto.updatedAt = now.bridgeDate
        dto.quotedMessageId = content.quotedMessageId
        if let channel = channel(cid: cid) {
            dto.channelName = channel.name
            dto.channelImageURL = channel.imageURL
        }

        let message = contentMessage(of: dto)
        try apply(content, to: message, cid: cid, user: currentUserDTO.user)
        message.locallyCreatedAt = now.bridgeDate
        message.createdAt = scheduledAt.bridgeDate
        message.updatedAt = now.bridgeDate
        message.localMessageState = .pendingSend

        return dto
    }

    func updateScheduledMessage(
        id: String,
        content: ScheduledMessageContent?,
        scheduledAt: Date?
    ) throws -> ScheduledMessageDTO {
        guard let dto = scheduledMessage(id: id), let message = dto.message else {
            throw ClientError.ScheduledMessageDoesNotExist(id: id)
        }
        guard let currentUserDTO = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }
        let cid = try ChannelId(cid: dto.cid)

        if let content {
            // Without a thread, the message keeps the thread it was scheduled in.
            var content = content
            if content.parentId == nil {
                content.parentId = message.parentMessageId
                content.showReplyInChannel = message.showReplyInChannel
            }
            try apply(content, to: message, cid: cid, user: currentUserDTO.user)
            dto.quotedMessageId = content.quotedMessageId
        }
        if let scheduledAt {
            dto.scheduledAt = scheduledAt.bridgeDate
            message.createdAt = scheduledAt.bridgeDate
            dto.hasPendingScheduledAt = !dto.isLocalOnly
        }
        dto.updatedAt = Date().bridgeDate
        dto.localErrorReason = nil
        dto.localErrorMessage = nil
        message.updatedAt = dto.updatedAt
        // A message that is not on the server yet is scheduled with its latest content.
        message.localMessageState = dto.isLocalOnly ? .pendingSend : .pendingSync

        return dto
    }

    func saveScheduledMessage(payload: ScheduledMessageResponse) throws -> ScheduledMessageDTO {
        let cid = try ChannelId(cid: payload.cid)
        let dto = ScheduledMessageDTO.loadOrCreate(id: payload.id, context: self)

        dto.cid = cid.rawValue
        dto.status = payload.status
        dto.failureReason = payload.failureReason
        dto.createdAt = payload.createdAt.bridgeDate
        dto.updatedAt = payload.updatedAt.bridgeDate
        if let channel = payload.channel {
            dto.channelName = channel.name
            dto.channelImageURL = channel.image.flatMap(URL.init(string:))
        }

        let message = contentMessage(of: dto)
        // Local changes win until they are sent to the server.
        guard !dto.hasLocalChanges else { return dto }

        let content = payload.message
        let user = try saveUser(payload: payload.user)
        dto.localErrorReason = nil
        dto.localErrorMessage = nil
        dto.scheduledAt = payload.scheduledAt.bridgeDate
        dto.hasPendingScheduledAt = false
        dto.quotedMessageId = content.quotedMessageId

        message.cid = cid.rawValue
        message.text = content.text
        message.type = content.parentId == nil ? MessageType.regular.rawValue : MessageType.reply.rawValue
        message.parentMessageId = content.parentId
        message.showReplyInChannel = content.showInChannel ?? false
        message.extraData = try JSONEncoder.default.encode(content.custom)
        message.isSilent = content.silent ?? false
        message.user = user
        message.mentionedUserIds = content.mentionedUsers ?? []
        message.mentionedUsers = Set(message.mentionedUserIds.compactMap { self.user(id: $0) })
        message.mentionedHere = content.mentionedHere ?? false
        message.mentionedChannel = content.mentionedChannel ?? false
        message.mentionedRoles = content.mentionedRoles ?? []
        message.quotedMessage = content.quotedMessageId.flatMap { MessageDTO.load(id: $0, context: self) }
        message.poll = content.pollId.flatMap { try? poll(id: $0) }
        message.pinned = content.pinned ?? false
        message.pinnedBy = message.pinned ? user : nil
        message.pinnedAt = message.pinned ? payload.scheduledAt.bridgeDate : nil
        message.pinExpires = message.pinned ? content.pinExpires?.bridgeDate : nil
        message.createdAt = payload.scheduledAt.bridgeDate
        message.updatedAt = payload.updatedAt.bridgeDate

        let attachments = try (content.attachments ?? []).enumerated().map { index, attachment in
            try saveAttachment(payload: attachment, id: AttachmentId(cid: cid, messageId: message.id, index: index))
        }
        message.attachments.subtracting(attachments).forEach { delete($0) }
        message.attachments = Set(attachments)

        return dto
    }

    func scheduledMessage(id: String) -> ScheduledMessageDTO? {
        ScheduledMessageDTO.load(id: id, context: self)
    }

    func deleteScheduledMessage(id: String) {
        guard let dto = scheduledMessage(id: id) else { return }
        // The sent message can have the same id and reuse the content, it is kept then.
        if let message = dto.message, message.channel == nil {
            delete(message)
        }
        delete(dto)
    }

    private func contentMessage(of dto: ScheduledMessageDTO) -> MessageDTO {
        if let message = dto.message {
            return message
        }

        let message = MessageDTO.loadOrCreate(id: dto.id, context: self, cache: nil)
        message.reactionScores = [:]
        message.reactionCounts = [:]
        message.reactionGroups = []
        message.mentionedGroupIds = []
        message.mentionedRoles = []
        message.skipPush = false
        message.skipEnrichUrl = false
        message.isSilent = false
        dto.message = message
        return message
    }

    private func apply(_ content: ScheduledMessageContent, to message: MessageDTO, cid: ChannelId, user: UserDTO) throws {
        message.cid = cid.rawValue
        message.text = content.text
        message.type = content.parentId == nil ? MessageType.regular.rawValue : MessageType.reply.rawValue
        message.parentMessageId = content.parentId
        message.showReplyInChannel = content.showReplyInChannel
        message.extraData = try JSONEncoder.default.encode(content.extraData)
        message.user = user
        message.mentionedUserIds = content.mentionedUserIds
        message.mentionedUsers = Set(content.mentionedUserIds.compactMap { self.user(id: $0) })
        message.mentionedHere = false
        message.mentionedChannel = false
        message.quotedMessage = content.quotedMessageId.flatMap { MessageDTO.load(id: $0, context: self) }

        message.attachments.forEach { delete($0) }
        message.attachments = Set(
            try content.attachments.enumerated().map { index, attachment in
                try createNewAttachment(attachment: attachment, id: AttachmentId(cid: cid, messageId: message.id, index: index))
            }
        )
    }
}

// MARK: - Converting to domain model

extension ScheduledMessageDTO {
    /// Snapshots the current state of `ScheduledMessageDTO` and returns an immutable model object from it.
    ///
    /// It does not fail for a deleted scheduled message, so its removal can be reported, but its content is not available then.
    func asModel() throws -> ScheduledMessage {
        let channelId = try ChannelId(cid: cid)
        let chatMessage: ChatMessage
        if let message, managedObjectContext != nil, !isDeleted {
            chatMessage = try message.asModel()
        } else if isDeleted || managedObjectContext == nil {
            // The relationships of a deleted scheduled message are cleared.
            chatMessage = .scheduledMessagePlaceholder(id: id, cid: channelId, scheduledAt: scheduledAt.bridgeDate)
        } else {
            throw InvalidModel(self)
        }

        let localChannel = channelName == nil && channelImageURL == nil ? managedObjectContext?.channel(cid: channelId) : nil
        return ScheduledMessage(
            id: id,
            cid: channelId,
            channel: ScheduledMessageChannel(
                cid: channelId,
                name: channelName ?? localChannel?.name,
                imageURL: channelImageURL ?? localChannel?.imageURL
            ),
            message: chatMessage,
            quotedMessageId: quotedMessageId,
            scheduledAt: scheduledAt.bridgeDate,
            status: ScheduledMessageStatus(rawValue: status),
            failureReason: failureReason.map(ScheduledMessageFailureReason.init(rawValue:)),
            localError: localErrorMessage.map {
                ScheduledMessageLocalError(reason: localErrorReason.map(ScheduledMessageErrorReason.init(rawValue:)), message: $0)
            },
            createdAt: createdAt.bridgeDate,
            updatedAt: updatedAt.bridgeDate
        )
    }
}

private extension ChatMessage {
    static func scheduledMessagePlaceholder(id: String, cid: ChannelId, scheduledAt: Date) -> ChatMessage {
        ChatMessage(
            id: id,
            cid: cid,
            text: "",
            type: .regular,
            command: nil,
            createdAt: scheduledAt,
            locallyCreatedAt: nil,
            updatedAt: scheduledAt,
            deletedAt: nil,
            arguments: nil,
            parentMessageId: nil,
            showReplyInChannel: false,
            replyCount: 0,
            extraData: [:],
            quotedMessage: nil,
            isBounced: false,
            isSilent: false,
            isShadowed: false,
            deletedForMe: false,
            reactionScores: [:],
            reactionCounts: [:],
            reactionGroups: [:],
            author: .placeholder(id: ""),
            mentionedUsers: [],
            mentionedHere: false,
            mentionedChannel: false,
            mentionedRoles: [],
            threadParticipants: [],
            attachments: [],
            latestReplies: [],
            localState: nil,
            isFlaggedByCurrentUser: false,
            latestReactions: [],
            currentUserReactions: [],
            isSentByCurrentUser: true,
            pinDetails: nil,
            translations: nil,
            originalLanguage: nil,
            moderationDetails: nil,
            readBy: [],
            poll: nil,
            textUpdatedAt: nil,
            draftReply: nil,
            reminder: nil,
            sharedLocation: nil
        )
    }
}

private extension ChatUser {
    static func placeholder(id: UserId) -> ChatUser {
        ChatUser(
            id: id,
            name: nil,
            imageURL: nil,
            isOnline: false,
            isBanned: false,
            isFlaggedByCurrentUser: false,
            userRole: .user,
            teamsRole: nil,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            deactivatedAt: nil,
            lastActiveAt: nil,
            teams: [],
            language: nil,
            avgResponseTime: nil,
            extraData: [:]
        )
    }
}
